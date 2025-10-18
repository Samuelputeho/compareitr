import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Service account key from environment
const SERVICE_ACCOUNT_KEY = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY') || ''

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { notification } = await req.json()
    
    if (!notification) {
      return new Response(
        JSON.stringify({ error: 'No notification data provided' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('📱 Processing notification:', notification)

    let userIds: string[] = []
    
    if (notification.user_id) {
      userIds = [notification.user_id]
    } else {
      const { data: allTokens, error: allTokensError } = await supabaseClient
        .from('device_tokens')
        .select('user_id, token, platform')
      
      if (allTokensError) {
        console.error('Error fetching all tokens:', allTokensError)
        return new Response(
          JSON.stringify({ error: 'Failed to fetch device tokens' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
      userIds = allTokens.map(token => token.user_id)
    }

    if (userIds.length === 0) {
      console.log('📱 No users to send notifications to')
      return new Response(
        JSON.stringify({ message: 'No users to send notifications to' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { data: deviceTokens, error: tokensError } = await supabaseClient
      .from('device_tokens')
      .select('user_id, token, platform')
      .in('user_id', userIds)

    if (tokensError) {
      console.error('Error fetching device tokens:', tokensError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch device tokens' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!deviceTokens || deviceTokens.length === 0) {
      console.log('📱 No device tokens found for users')
      return new Response(
        JSON.stringify({ message: 'No device tokens found' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`📱 Found ${deviceTokens.length} device tokens`)

    // Parse service account key
    let serviceAccount
    try {
      serviceAccount = JSON.parse(SERVICE_ACCOUNT_KEY)
    } catch (e) {
      console.error('❌ Invalid service account key:', e)
      return new Response(
        JSON.stringify({ error: 'Invalid service account key' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get access token using service account
    const jwt = await generateJWT(serviceAccount)
    
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    })

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text()
      console.error('❌ Failed to get access token:', errorText)
      return new Response(
        JSON.stringify({ error: 'Failed to get access token', details: errorText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const tokenData = await tokenResponse.json()
    const accessToken = tokenData.access_token

    const results = []
    for (const deviceToken of deviceTokens) {
      try {
        // Use Firebase Cloud Messaging API v1
        const fcmResponse = await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: deviceToken.token,
              notification: {
                title: notification.title,
                body: notification.message,
                image: notification.image_url || undefined,
              },
              data: {
                type: notification.type || 'system',
                notification_id: notification.id,
                action_url: notification.action_url || '',
              },
              android: {
                priority: 'high',
                notification: {
                  sound: 'default',
                  channel_id: 'default',
                },
              },
            },
          }),
        })

        const fcmResult = await fcmResponse.json()
        
        if (fcmResponse.ok) {
          console.log(`✅ Push sent to ${deviceToken.platform} user ${deviceToken.user_id}`)
          results.push({
            user_id: deviceToken.user_id,
            platform: deviceToken.platform,
            status: 'success',
          })
        } else {
          console.error(`❌ Push failed for user ${deviceToken.user_id}:`, fcmResult)
          results.push({
            user_id: deviceToken.user_id,
            platform: deviceToken.platform,
            status: 'failed',
            error: fcmResult,
          })
        }
      } catch (error) {
        console.error(`❌ Error sending push to user ${deviceToken.user_id}:`, error)
        results.push({
          user_id: deviceToken.user_id,
          platform: deviceToken.platform,
          status: 'error',
          error: error.message,
        })
      }
    }

    const successCount = results.filter(r => r.status === 'success').length
    const failCount = results.filter(r => r.status !== 'success').length

    console.log(`📱 Push notification results: ${successCount} sent, ${failCount} failed`)

    return new Response(
      JSON.stringify({
        message: 'Push notifications processed',
        sent: successCount,
        failed: failCount,
        results,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('❌ Error in send-push-notification function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Generate JWT for service account authentication
async function generateJWT(serviceAccount: any): Promise<string> {
  const header = {
    alg: 'RS256',
    typ: 'JWT',
    kid: serviceAccount.private_key_id,
  }

  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  // Encode header and payload
  const encodedHeader = btoa(JSON.stringify(header)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
  
  const signatureInput = `${encodedHeader}.${encodedPayload}`

  try {
    // Import the Web Crypto API for signing
    const privateKey = await crypto.subtle.importKey(
      'pkcs8',
      base64ToArrayBuffer(serviceAccount.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, '')),
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['sign']
    )

    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      privateKey,
      new TextEncoder().encode(signatureInput)
    )

    const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '')

    return `${signatureInput}.${encodedSignature}`
  } catch (error) {
    console.error('❌ Error generating JWT:', error)
    throw error
  }
}

// Helper function to convert base64 to ArrayBuffer
function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const binaryString = atob(base64)
  const bytes = new Uint8Array(binaryString.length)
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }
  return bytes.buffer
}
