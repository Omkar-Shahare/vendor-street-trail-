/*
  # Vendor-Supplier Management System Schema

  ## Overview
  This migration creates the complete database schema for a vendor-supplier marketplace
  that helps street food vendors find, compare, and order raw materials from suppliers.

  ## New Tables

  ### 1. `vendors`
  Stores vendor (street food business) profile information
  - `id` (uuid, primary key) - Unique vendor identifier
  - `user_id` (uuid, references auth.users) - Links to authentication user
  - `business_name` (text) - Name of the vendor's business
  - `owner_name` (text) - Owner's full name
  - `phone` (text) - Contact phone number
  - `address` (text) - Business address
  - `city` (text) - City location
  - `state` (text) - State location
  - `pincode` (text) - Postal code
  - `business_type` (text) - Type of food business (e.g., 'street_food', 'restaurant')
  - `gst_number` (text, optional) - GST registration number
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 2. `suppliers`
  Stores supplier profile information
  - `id` (uuid, primary key) - Unique supplier identifier
  - `user_id` (uuid, references auth.users) - Links to authentication user
  - `business_name` (text) - Name of supplier business
  - `owner_name` (text) - Owner's full name
  - `phone` (text) - Contact phone number
  - `email` (text) - Business email
  - `address` (text) - Business address
  - `city` (text) - City location
  - `state` (text) - State location
  - `pincode` (text) - Postal code
  - `gst_number` (text, optional) - GST registration number
  - `fssai_license` (text, optional) - FSSAI license number
  - `rating` (numeric) - Average supplier rating (0-5)
  - `total_reviews` (integer) - Total number of reviews
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 3. `products`
  Stores products/raw materials offered by suppliers
  - `id` (uuid, primary key) - Unique product identifier
  - `supplier_id` (uuid, references suppliers) - Which supplier offers this
  - `name` (text) - Product name (e.g., 'Tomatoes', 'Rice')
  - `category` (text) - Product category (e.g., 'vegetables', 'grains')
  - `unit` (text) - Unit of measurement (e.g., 'kg', 'liter')
  - `price_per_unit` (numeric) - Price per unit
  - `min_order_quantity` (numeric) - Minimum order quantity
  - `stock_available` (boolean) - Whether in stock
  - `description` (text, optional) - Product description
  - `image_url` (text, optional) - Product image URL
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 4. `orders`
  Stores orders placed by vendors to suppliers
  - `id` (uuid, primary key) - Unique order identifier
  - `vendor_id` (uuid, references vendors) - Vendor who placed order
  - `supplier_id` (uuid, references suppliers) - Supplier fulfilling order
  - `order_number` (text, unique) - Human-readable order number
  - `status` (text) - Order status: pending, confirmed, delivered, cancelled
  - `total_amount` (numeric) - Total order amount
  - `delivery_address` (text) - Delivery address
  - `delivery_date` (date, optional) - Expected/actual delivery date
  - `notes` (text, optional) - Order notes
  - `created_at` (timestamptz) - Order placed timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 5. `order_items`
  Stores individual items in each order
  - `id` (uuid, primary key) - Unique order item identifier
  - `order_id` (uuid, references orders) - Parent order
  - `product_id` (uuid, references products) - Ordered product
  - `quantity` (numeric) - Quantity ordered
  - `unit_price` (numeric) - Price per unit at time of order
  - `total_price` (numeric) - Total price for this item
  - `created_at` (timestamptz) - Record creation timestamp

  ## Security (Row Level Security)

  All tables have RLS enabled with the following policies:

  ### Vendors Table
  - Authenticated users can read their own vendor profile
  - Authenticated users can insert their own vendor profile
  - Authenticated users can update their own vendor profile

  ### Suppliers Table
  - Anyone (authenticated or not) can read all supplier profiles (for browsing)
  - Authenticated users can insert their own supplier profile
  - Authenticated users can update their own supplier profile

  ### Products Table
  - Anyone can read all products (for browsing)
  - Suppliers can insert products for their own business
  - Suppliers can update their own products
  - Suppliers can delete their own products

  ### Orders Table
  - Vendors can read their own orders
  - Suppliers can read orders placed to them
  - Vendors can create new orders
  - Vendors can update their pending orders
  - Suppliers can update order status

  ### Order Items Table
  - Order items are readable by anyone who can read the parent order
  - Order items are insertable by vendors creating orders

  ## Indexes
  - Foreign key indexes for performance
  - Index on supplier rating for sorting
  - Index on order status for filtering
  - Index on product category for filtering

  ## Important Notes
  1. All monetary values use numeric type for precision
  2. Timestamps use timestamptz for timezone awareness
  3. User authentication is handled by Supabase Auth
  4. RLS policies ensure data isolation and security
*/

-- Create vendors table
CREATE TABLE IF NOT EXISTS vendors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  business_name text NOT NULL,
  owner_name text NOT NULL,
  phone text NOT NULL,
  address text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  pincode text NOT NULL,
  business_type text NOT NULL DEFAULT 'street_food',
  gst_number text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create suppliers table
CREATE TABLE IF NOT EXISTS suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  business_name text NOT NULL,
  owner_name text NOT NULL,
  phone text NOT NULL,
  email text NOT NULL,
  address text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  pincode text NOT NULL,
  gst_number text,
  fssai_license text,
  rating numeric(2,1) DEFAULT 0 NOT NULL CHECK (rating >= 0 AND rating <= 5),
  total_reviews integer DEFAULT 0 NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id uuid REFERENCES suppliers(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  category text NOT NULL,
  unit text NOT NULL,
  price_per_unit numeric(10,2) NOT NULL CHECK (price_per_unit >= 0),
  min_order_quantity numeric(10,2) DEFAULT 1 NOT NULL CHECK (min_order_quantity > 0),
  stock_available boolean DEFAULT true NOT NULL,
  description text,
  image_url text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id uuid REFERENCES vendors(id) ON DELETE CASCADE NOT NULL,
  supplier_id uuid REFERENCES suppliers(id) ON DELETE CASCADE NOT NULL,
  order_number text UNIQUE NOT NULL,
  status text DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'confirmed', 'delivered', 'cancelled')),
  total_amount numeric(10,2) NOT NULL CHECK (total_amount >= 0),
  delivery_address text NOT NULL,
  delivery_date date,
  notes text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  product_id uuid REFERENCES products(id) ON DELETE RESTRICT NOT NULL,
  quantity numeric(10,2) NOT NULL CHECK (quantity > 0),
  unit_price numeric(10,2) NOT NULL CHECK (unit_price >= 0),
  total_price numeric(10,2) NOT NULL CHECK (total_price >= 0),
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_vendors_user_id ON vendors(user_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_user_id ON suppliers(user_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_rating ON suppliers(rating DESC);
CREATE INDEX IF NOT EXISTS idx_products_supplier_id ON products(supplier_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_vendor_id ON orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_orders_supplier_id ON orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Enable Row Level Security
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Vendors RLS Policies
CREATE POLICY "Users can view own vendor profile"
  ON vendors FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own vendor profile"
  ON vendors FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own vendor profile"
  ON vendors FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Suppliers RLS Policies
CREATE POLICY "Anyone can view all suppliers"
  ON suppliers FOR SELECT
  TO authenticated, anon
  USING (true);

CREATE POLICY "Users can insert own supplier profile"
  ON suppliers FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own supplier profile"
  ON suppliers FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Products RLS Policies
CREATE POLICY "Anyone can view all products"
  ON products FOR SELECT
  TO authenticated, anon
  USING (true);

CREATE POLICY "Suppliers can insert own products"
  ON products FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = products.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can update own products"
  ON products FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = products.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = products.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can delete own products"
  ON products FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = products.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  );

-- Orders RLS Policies
CREATE POLICY "Vendors can view own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM vendors
      WHERE vendors.id = orders.vendor_id
      AND vendors.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can view orders to them"
  ON orders FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = orders.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  );

CREATE POLICY "Vendors can create orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vendors
      WHERE vendors.id = orders.vendor_id
      AND vendors.user_id = auth.uid()
    )
  );

CREATE POLICY "Vendors can update own pending orders"
  ON orders FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM vendors
      WHERE vendors.id = orders.vendor_id
      AND vendors.user_id = auth.uid()
    )
    AND status = 'pending'
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vendors
      WHERE vendors.id = orders.vendor_id
      AND vendors.user_id = auth.uid()
    )
  );

CREATE POLICY "Suppliers can update order status"
  ON orders FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = orders.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM suppliers
      WHERE suppliers.id = orders.supplier_id
      AND suppliers.user_id = auth.uid()
    )
  );

-- Order Items RLS Policies
CREATE POLICY "Users can view order items for their orders"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND (
        EXISTS (
          SELECT 1 FROM vendors
          WHERE vendors.id = orders.vendor_id
          AND vendors.user_id = auth.uid()
        )
        OR EXISTS (
          SELECT 1 FROM suppliers
          WHERE suppliers.id = orders.supplier_id
          AND suppliers.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Vendors can insert order items for their orders"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      JOIN vendors ON vendors.id = orders.vendor_id
      WHERE orders.id = order_items.order_id
      AND vendors.user_id = auth.uid()
    )
  );

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER update_vendors_updated_at
  BEFORE UPDATE ON vendors
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at
  BEFORE UPDATE ON suppliers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
