# Custom Order Number Setup (C0001 Format)

## Overview
Your app now generates branded order numbers like **C0001, C0002, C0003** instead of random UUIDs.

---

## Database Setup Required

You need to run the SQL script in your Supabase database:

### Step-by-Step:

1. **Go to Supabase Dashboard**
   - Login to [supabase.com](https://supabase.com)
   - Select your project

2. **Open SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Run the Setup Script**
   - Copy the entire contents of `database_order_number_setup.sql`
   - Paste into the SQL editor
   - Click "Run" or press `Ctrl+Enter`

4. **Verify Success**
   - You should see: "Success. No rows returned"
   - Check that the table was created:
   ```sql
   SELECT * FROM order_counter;
   ```
   - Should show: `{ id: 1, counter: 0, updated_at: ... }`

---

## How It Works

### Order Number Generation:

**When user places order:**
```
1. Call database function: get_next_order_number()
2. Database increments counter: 0 → 1
3. Returns: 1
4. App formats it: C + 0001 = "C0001"
5. Saves order with orderId = "C0001"
```

**Next order:**
```
Counter: 1 → 2
Returns: 2
Format: "C0002"
```

### Order Number Format:
- **C** - Your brand prefix (CompareIt)
- **0001** - 4-digit padded number (0001, 0002, ..., 9999, 10000)

Examples:
- 1st order: `C0001`
- 10th order: `C0010`
- 100th order: `C0100`
- 1000th order: `C1000`
- 10,000th order: `C10000` (expands to 5 digits)

---

## Fallback System

**If database function doesn't exist or fails:**
- Uses timestamp-based fallback: `C12345678`
- Still unique and branded
- Works offline/during database issues

So your app will work even if you haven't run the SQL script yet!

---

## Benefits

### For Customers:
- ✅ Easy to remember: "My order is C0042"
- ✅ Easy to communicate: "I'm calling about order C-zero-zero-forty-two"
- ✅ Professional appearance
- ✅ Shorter than UUID (6 chars vs 36 chars)

### For You:
- ✅ Branded order numbers
- ✅ Sequential (helps track growth)
- ✅ Easy to reference
- ✅ Can tell which order came first

### Technical:
- ✅ Atomic/thread-safe (no duplicate numbers)
- ✅ Works with multiple concurrent orders
- ✅ Never resets (unless you manually reset)
- ✅ Fallback system for reliability

---

## Testing

### Test the Database Function (After SQL setup):

In Supabase SQL Editor:
```sql
-- Test: Generate some order numbers
SELECT get_next_order_number();  -- Returns: 1
SELECT get_next_order_number();  -- Returns: 2
SELECT get_next_order_number();  -- Returns: 3

-- Check current counter
SELECT * FROM order_counter;  -- Shows counter = 3
```

### Test in Your App:

1. Hot restart the app
2. Add items to cart
3. Go through checkout
4. Place an order
5. Check console logs for: `📦 Generated order number: C0001`
6. Check order page - should show "Order #C0001"

---

## Display in App

Order numbers now appear as:
- Order list: "Order #C0001" (first 8 chars, which is full order number)
- Order details: "Order #C0001"
- Notifications: "Your order C0001 is ready"

---

## Starting Number

By default, starts at 1 (C0001).

**To start at a different number:**
```sql
-- Start at 100 (orders will be C0100, C0101, etc.)
UPDATE order_counter SET counter = 99 WHERE id = 1;

-- Start at 1000 (orders will be C1000, C1001, etc.)
UPDATE order_counter SET counter = 999 WHERE id = 1;
```

---

## Security

The database function is:
- ✅ **SECURITY DEFINER** - Runs with creator's permissions
- ✅ **Atomic** - No race conditions
- ✅ **Thread-safe** - Handles concurrent orders
- ✅ **Granted to authenticated users** - Your logged-in customers can call it

---

## Maintenance

### View Current Counter:
```sql
SELECT * FROM order_counter;
```

### Reset Counter (careful!):
```sql
UPDATE order_counter SET counter = 0 WHERE id = 1;
```

### See All Orders with New Format:
```sql
SELECT order_id, order_status, created_at 
FROM orders 
WHERE order_id LIKE 'C%'
ORDER BY created_at DESC;
```

---

## Migration Note

**Existing Orders:**
- Old orders with UUID format still work fine
- New orders use C0001 format
- Both formats coexist peacefully
- No data migration needed

---

## Troubleshooting

### Issue: "RPC function not found"
**Solution:** Run the `database_order_number_setup.sql` script

### Issue: Getting fallback numbers (C12345678)
**Solution:** Database function not set up, run SQL script

### Issue: Duplicate order numbers
**Solution:** Shouldn't happen (atomic function), check database

### Issue: Want to change prefix (C → something else)
**Solution:** Edit `order_number_service.dart`, change `'C'` to your desired prefix

---

## Future Enhancements

You could add:
- **Different prefixes for different order types**: C (regular), E (express), P (pickup)
- **Reset annually**: C2025-0001, C2026-0001
- **Store-specific**: CW0001 (Windhoek), CS0001 (Swakopmund)

Just ask and I can implement these! 🚀

