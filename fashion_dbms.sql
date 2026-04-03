-- HỆ THỐNG QUẢN LÝ BÁN QUẦN ÁO
-- sử dụng SQL Server 
-- Bao gồm: Schema + Mock Data + 10 Views
-- + 10 Procedures + 10 Functions + 12 Triggers
-- + 10 Indexes
-- Phiên bản: FINAL ròi huhu

USE master;
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'ClothingStoreDB')
    DROP DATABASE ClothingStoreDB;
GO

CREATE DATABASE ClothingStoreDB
    COLLATE Vietnamese_CI_AS;
GO

USE ClothingStoreDB;
GO


-- PHẦN 1: TẠO CẤU TRÚC BẢNG
-- 1.1 ROLES
CREATE TABLE Roles (
    role_id     INT PRIMARY KEY IDENTITY(1,1),
    role_name   NVARCHAR(50)  NOT NULL UNIQUE,
    description NVARCHAR(200)
);
GO

-- 1.2 PERMISSIONS
CREATE TABLE Permissions (
    permission_id INT PRIMARY KEY IDENTITY(1,1),
    module        NVARCHAR(50) NOT NULL,
    action        NVARCHAR(50) NOT NULL,
    CONSTRAINT UQ_perm UNIQUE (module, action)
);
GO

-- 1.3 ROLE PERMISSIONS (RBAC bridge)
CREATE TABLE RolePermissions (
    role_id       INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id)       REFERENCES Roles(role_id),
    FOREIGN KEY (permission_id) REFERENCES Permissions(permission_id)
);
GO

-- 1.4 USERS
CREATE TABLE Users (
    user_id       INT PRIMARY KEY IDENTITY(1,1),
    role_id       INT          NOT NULL,
    full_name     NVARCHAR(100) NOT NULL,
    email         NVARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(15),
    password_hash VARCHAR(255) NOT NULL,
    is_active     BIT          DEFAULT 1,
    created_at    DATETIME     DEFAULT GETDATE(),
    CONSTRAINT CHK_user_email CHECK (email LIKE '%@%.%'),
    FOREIGN KEY (role_id) REFERENCES Roles(role_id)
);
GO

-- 1.5 CATEGORIES (tự tham chiếu cha-con)
CREATE TABLE Categories (
    category_id   INT PRIMARY KEY IDENTITY(1,1),
    parent_id     INT NULL,
    category_name NVARCHAR(100) NOT NULL,
    slug          VARCHAR(100),
    FOREIGN KEY (parent_id) REFERENCES Categories(category_id)
);
GO

-- 1.6 BRANDS
CREATE TABLE Brands (
    brand_id   INT PRIMARY KEY IDENTITY(1,1),
    brand_name NVARCHAR(100) NOT NULL UNIQUE,
    country    NVARCHAR(50),
    logo_url   VARCHAR(255)
);
GO

-- 1.7 PRODUCTS
CREATE TABLE Products (
    product_id   INT PRIMARY KEY IDENTITY(1,1),
    category_id  INT           NOT NULL,
    brand_id     INT           NOT NULL,
    product_name NVARCHAR(200) NOT NULL,
    description  NVARCHAR(MAX),
    base_price   DECIMAL(12,2) NOT NULL,
    is_active    BIT           DEFAULT 1,
    created_at   DATETIME      DEFAULT GETDATE(),
    CONSTRAINT CHK_product_price CHECK (base_price > 0),
    FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    FOREIGN KEY (brand_id)    REFERENCES Brands(brand_id)
);
GO

-- 1.8 PRODUCT VARIANTS (size + màu)
CREATE TABLE ProductVariants (
    variant_id  INT PRIMARY KEY IDENTITY(1,1),
    product_id  INT           NOT NULL,
    size        NVARCHAR(10),
    color       NVARCHAR(50),
    sku         VARCHAR(60)   NOT NULL UNIQUE,
    extra_price DECIMAL(12,2) DEFAULT 0,
    image_url   VARCHAR(255),
    CONSTRAINT CHK_variant_extra_price CHECK (extra_price >= 0),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);
GO

-- 1.9 WAREHOUSES
CREATE TABLE Warehouses (
    warehouse_id   INT PRIMARY KEY IDENTITY(1,1),
    warehouse_name NVARCHAR(100) NOT NULL,
    address        NVARCHAR(300)
);
GO

-- 1.10 INVENTORY
CREATE TABLE Inventory (
    inventory_id INT PRIMARY KEY IDENTITY(1,1),
    variant_id   INT  NOT NULL,
    warehouse_id INT  NOT NULL,
    quantity     INT  DEFAULT 0,
    min_quantity INT  DEFAULT 5,
    updated_at   DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_inv     UNIQUE (variant_id, warehouse_id),
    CONSTRAINT CHK_inv_qty CHECK (quantity >= 0),
    CONSTRAINT CHK_inv_min CHECK (min_quantity >= 0),
    FOREIGN KEY (variant_id)   REFERENCES ProductVariants(variant_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id)
);
GO

-- 1.11 SUPPLIERS
CREATE TABLE Suppliers (
    supplier_id     INT PRIMARY KEY IDENTITY(1,1),
    supplier_name   NVARCHAR(200) NOT NULL,
    contact_person  NVARCHAR(100),
    phone           VARCHAR(15),
    email           NVARCHAR(100),
    address         NVARCHAR(300),
    is_active       BIT DEFAULT 1
);
GO

-- 1.12 STOCK RECEIPTS
CREATE TABLE StockReceipts (
    receipt_id   INT PRIMARY KEY IDENTITY(1,1),
    supplier_id  INT           NOT NULL,
    warehouse_id INT           NOT NULL,
    created_by   INT           NOT NULL,
    receipt_date DATETIME      DEFAULT GETDATE(),
    total_amount DECIMAL(14,2),
    note         NVARCHAR(300),
    FOREIGN KEY (supplier_id)  REFERENCES Suppliers(supplier_id),
    FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id),
    FOREIGN KEY (created_by)   REFERENCES Users(user_id)
);
GO

CREATE TABLE StockReceiptItems (
    item_id    INT PRIMARY KEY IDENTITY(1,1),
    receipt_id INT           NOT NULL,
    variant_id INT           NOT NULL,
    quantity   INT           NOT NULL,
    unit_cost  DECIMAL(12,2) NOT NULL,
    CONSTRAINT CHK_sri_qty  CHECK (quantity > 0),
    CONSTRAINT CHK_sri_cost CHECK (unit_cost > 0),
    FOREIGN KEY (receipt_id) REFERENCES StockReceipts(receipt_id),
    FOREIGN KEY (variant_id) REFERENCES ProductVariants(variant_id)
);
GO

-- 1.13 CUSTOMERS
CREATE TABLE Customers (
    customer_id    INT PRIMARY KEY IDENTITY(1,1),
    full_name      NVARCHAR(100) NOT NULL,
    email          NVARCHAR(100),
    phone          VARCHAR(15),
    address        NVARCHAR(300),
    gender         NVARCHAR(10),
    birthday       DATE,
    loyalty_points INT      DEFAULT 0,
    created_at     DATETIME DEFAULT GETDATE(),
    CONSTRAINT CHK_customer_email   CHECK (email IS NULL OR email LIKE '%@%.%'),
    CONSTRAINT CHK_customer_gender  CHECK (gender IS NULL OR gender IN (N'Nam', N'Nữ', N'Khác'))
);
GO

-- 1.14 ORDERS
-- is_stock_reserved: cờ đánh dấu kho đã bị trừ lúc đặt hàng (RESERVE model)
CREATE TABLE Orders (
    order_id          INT PRIMARY KEY IDENTITY(1,1),
    customer_id       INT           NOT NULL,
    created_by        INT           NOT NULL,
    order_date        DATETIME      DEFAULT GETDATE(),
    status            NVARCHAR(30)  DEFAULT 'pending',
    shipping_address  NVARCHAR(300),
    discount_amount   DECIMAL(12,2) DEFAULT 0,
    total_amount      DECIMAL(14,2) NOT NULL,
    note              NVARCHAR(300),
    is_stock_reserved BIT           DEFAULT 0,
    CONSTRAINT CHK_order_status   CHECK (status IN ('pending','confirmed','shipping','shipped','delivered','cancelled')),
    CONSTRAINT CHK_order_total    CHECK (total_amount >= 0),
    CONSTRAINT CHK_order_discount CHECK (discount_amount >= 0),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (created_by)  REFERENCES Users(user_id)
);
GO

-- 1.15 ORDER ITEMS
CREATE TABLE OrderItems (
    item_id    INT PRIMARY KEY IDENTITY(1,1),
    order_id   INT           NOT NULL,
    variant_id INT           NOT NULL,
    quantity   INT           NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    CONSTRAINT CHK_oi_qty   CHECK (quantity > 0),
    CONSTRAINT CHK_oi_price CHECK (unit_price > 0),
    FOREIGN KEY (order_id)   REFERENCES Orders(order_id),
    FOREIGN KEY (variant_id) REFERENCES ProductVariants(variant_id)
);
GO

-- 1.16 PAYMENTS
CREATE TABLE Payments (
    payment_id      INT PRIMARY KEY IDENTITY(1,1),
    order_id        INT           NOT NULL,
    payment_date    DATETIME      DEFAULT GETDATE(),
    amount          DECIMAL(14,2) NOT NULL,
    method          NVARCHAR(50),
    status          NVARCHAR(20)  DEFAULT 'completed',
    transaction_ref VARCHAR(100),
    CONSTRAINT CHK_payment_amount CHECK (amount > 0),
    CONSTRAINT CHK_payment_status CHECK (status IN ('pending','completed','failed','refunded')),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);
GO

-- 1.17 AUDIT LOG
CREATE TABLE AuditLog (
    log_id     INT PRIMARY KEY IDENTITY(1,1),
    table_name NVARCHAR(50),
    action     NVARCHAR(20),
    record_id  INT,
    changed_by NVARCHAR(100) DEFAULT SYSTEM_USER,
    changed_at DATETIME      DEFAULT GETDATE(),
    detail     NVARCHAR(500)
);
GO

-- PHẦN 2: INSERT DỮ LIỆU MẪU

-- ROLES
INSERT INTO Roles (role_name, description) VALUES
(N'Admin',           N'Toàn quyền hệ thống'),
(N'Manager',         N'Quản lý cửa hàng, xem báo cáo'),
(N'Sales Staff',     N'Nhân viên bán hàng'),
(N'Warehouse Staff', N'Nhân viên kho'),
(N'Viewer',          N'Chỉ xem báo cáo');

-- PERMISSIONS
INSERT INTO Permissions (module, action) VALUES
('products','read'),('products','create'),('products','update'),('products','delete'),
('inventory','read'),('inventory','create'),('inventory','update'),('inventory','delete'),
('orders','read'),('orders','create'),('orders','update'),('orders','delete'),
('users','read'),('users','create'),('users','update'),('users','delete'),
('reports','read'),('suppliers','read'),('suppliers','create'),('suppliers','update');

-- ROLE PERMISSIONS
INSERT INTO RolePermissions (role_id, permission_id)
SELECT 1, permission_id FROM Permissions; -- Admin: tất cả

INSERT INTO RolePermissions (role_id, permission_id) -- Manager
SELECT 2, permission_id FROM Permissions
WHERE (module IN ('products','inventory','orders','reports','suppliers') AND action IN ('read','update'))
   OR (module = 'orders' AND action = 'create');

INSERT INTO RolePermissions (role_id, permission_id) -- Sales Staff
SELECT 3, permission_id FROM Permissions
WHERE (module = 'orders'    AND action IN ('read','create','update'))
   OR (module = 'products'  AND action = 'read')
   OR (module = 'inventory' AND action = 'read');

INSERT INTO RolePermissions (role_id, permission_id) -- Warehouse Staff
SELECT 4, permission_id FROM Permissions
WHERE module IN ('inventory','suppliers') AND action IN ('read','create','update');

INSERT INTO RolePermissions (role_id, permission_id) -- Viewer
SELECT 5, permission_id FROM Permissions WHERE action = 'read';

-- USERS
INSERT INTO Users (role_id, full_name, email, phone, password_hash) VALUES
(1, N'Nguyễn Văn Admin',    'admin@store.vn',     '0901000001', 'hash_admin'),
(2, N'Trần Thị Manager',    'manager@store.vn',   '0901000002', 'hash_mgr'),
(3, N'Lê Văn Sales 1',      'sales1@store.vn',    '0901000003', 'hash_s1'),
(3, N'Phạm Thị Sales 2',    'sales2@store.vn',    '0901000004', 'hash_s2'),
(3, N'Ngô Thị Sales 3',     'sales3@store.vn',    '0901000006', 'hash_s3'),
(4, N'Hoàng Văn Warehouse', 'warehouse@store.vn', '0901000005', 'hash_wh'),
(5, N'Vũ Minh Viewer',      'viewer@store.vn',    '0901000007', 'hash_vw');

-- CATEGORIES
INSERT INTO Categories (parent_id, category_name, slug) VALUES
(NULL,N'Áo','ao'),          (NULL,N'Quần','quan'),
(NULL,N'Váy & Đầm','vay-dam'), (NULL,N'Phụ kiện','phu-kien'),
(1,N'Áo thun','ao-thun'),   (1,N'Áo sơ mi','ao-so-mi'),
(1,N'Áo khoác','ao-khoac'), (1,N'Áo hoodie','ao-hoodie'),
(2,N'Quần jean','quan-jean'),(2,N'Quần kaki','quan-kaki'),
(2,N'Quần short','quan-short'),(3,N'Váy ngắn','vay-ngan'),
(3,N'Đầm dài','dam-dai'),   (4,N'Mũ & Nón','mu-non'),
(4,N'Thắt lưng','that-lung');

-- BRANDS
INSERT INTO Brands (brand_name, country) VALUES
(N'Local Brand VN','Việt Nam'),(N'SkyWear','Việt Nam'),
(N'UrbanFit','Việt Nam'),     (N'TrendyHouse','Việt Nam'),
(N'EcoThreads','Việt Nam'),   (N'StreetStyle Co','Việt Nam'),
(N'PureBasic','Việt Nam'),    (N'NightOwl Apparel','Việt Nam');

-- WAREHOUSES
INSERT INTO Warehouses (warehouse_name, address) VALUES
(N'Kho Hà Nội',        N'123 Đường Láng, Đống Đa, Hà Nội'),
(N'Kho Hồ Chí Minh',  N'456 Lý Thường Kiệt, Q.10, TP.HCM'),
(N'Kho Đà Nẵng',      N'789 Nguyễn Văn Linh, Đà Nẵng');

-- SUPPLIERS
INSERT INTO Suppliers (supplier_name, contact_person, phone, email, address) VALUES
(N'Dệt may Phong Phú',  N'Nguyễn Thành Long','0281000001','phongphu@sup.vn', N'Bình Dương'),
(N'Xưởng may Hoàng Gia',N'Trần Minh Hoàng',  '0281000002','hoanggia@sup.vn', N'TP.HCM'),
(N'Vải Việt Tiến',      N'Lê Thị Thu',        '0281000003','viettien@sup.vn', N'Long An'),
(N'May mặc An Phát',    N'Phạm Văn An',       '0281000004','anphat@sup.vn',   N'Hà Nội'),
(N'Xưởng Minh Tâm',    N'Võ Minh Tâm',       '0281000005','minhtam@sup.vn',  N'Đà Nẵng');

-- PRODUCTS
INSERT INTO Products (category_id, brand_id, product_name, base_price) VALUES
-- Áo thun (cat 5) × 20
(5,1,N'Áo thun nam basic trắng',150000),(5,1,N'Áo thun nam basic đen',150000),
(5,2,N'Áo thun SkyWear cổ tròn',180000),(5,2,N'Áo thun SkyWear in logo',200000),
(5,3,N'Áo thun UrbanFit oversize',220000),(5,3,N'Áo thun UrbanFit crop',190000),
(5,4,N'Áo thun TrendyHouse sọc',175000),(5,5,N'Áo thun EcoThreads cotton',210000),
(5,6,N'Áo thun StreetStyle tie-dye',230000),(5,7,N'Áo thun PureBasic ribbed',165000),
(5,1,N'Áo thun nữ cổ V basic',155000),(5,2,N'Áo thun nữ SkyWear lụa',195000),
(5,3,N'Áo thun UrbanFit puff sleeve',205000),(5,4,N'Áo thun TrendyHouse bướm',185000),
(5,8,N'Áo thun NightOwl in hình',240000),(5,5,N'Áo thun EcoThreads tái chế',215000),
(5,1,N'Áo thun polo basic',190000),(5,2,N'Áo thun polo cổ bẻ',220000),
(5,6,N'Áo thun graphic tee',235000),(5,7,N'Áo thun sport mesh',195000),
-- Áo sơ mi (cat 6) × 12
(6,1,N'Áo sơ mi nam trắng',280000),(6,2,N'Áo sơ mi kẻ caro',320000),
(6,3,N'Áo sơ mi linen',350000),(6,4,N'Áo sơ mi ngắn tay',290000),
(6,5,N'Áo sơ mi bamboo',380000),(6,6,N'Áo sơ mi denim',400000),
(6,7,N'Áo sơ mi Oxford',310000),(6,8,N'Áo sơ mi flannel',360000),
(6,1,N'Áo sơ mi nữ basic',270000),(6,2,N'Áo sơ mi nữ lụa',330000),
(6,3,N'Áo sơ mi oversized',340000),(6,4,N'Áo sơ mi Hawaii',305000),
-- Áo khoác (cat 7) × 12
(7,1,N'Áo khoác bomber basic',450000),(7,2,N'Áo khoác windbreaker',520000),
(7,3,N'Áo khoác denim',550000),(7,4,N'Áo khoác puffer',680000),
(7,5,N'Áo khoác EcoThreads',590000),(7,6,N'Áo khoác oversized',480000),
(7,7,N'Áo khoác blazer',720000),(7,8,N'Áo khoác NightOwl',850000),
(7,4,N'Áo khoác hoodie zip',580000),(7,5,N'Áo khoác rain jacket',610000),
(7,6,N'Áo khoác teddy',640000),(7,7,N'Áo khoác trench',780000),
-- Áo hoodie (cat 8) × 10
(8,1,N'Hoodie basic không mũ',320000),(8,2,N'Hoodie có mũ',380000),
(8,3,N'Hoodie crop',360000),(8,4,N'Hoodie in chữ',350000),
(8,5,N'Hoodie fleece',410000),(8,6,N'Hoodie tie-dye',395000),
(8,7,N'Hoodie waffle',370000),(8,8,N'Hoodie zip-up',420000),
(8,5,N'Hoodie zip dày',440000),(8,7,N'Hoodie basic zip',390000),
-- Quần jean (cat 9) × 15
(9,1,N'Quần jean slim xanh nhạt',420000),(9,2,N'Quần jean skinny',450000),
(9,3,N'Quần jean wide leg',480000),(9,4,N'Quần jean boyfriend',460000),
(9,5,N'Quần jean ripped',500000),(9,6,N'Quần jean baggy',520000),
(9,7,N'Quần jean straight',430000),(9,8,N'Quần jean mom jeans',455000),
(9,1,N'Quần jean nam đen slim',440000),(9,2,N'Quần jean raw edge',470000),
(9,3,N'Quần jean high-waist',445000),(9,6,N'Quần jean tapered',510000),
(9,7,N'Quần jean flare',495000),(9,4,N'Quần jean slim đen',435000),
(9,5,N'Quần jean xanh đậm slim',425000),
-- Quần kaki (cat 10) × 10
(10,1,N'Quần kaki slim be',350000),(10,2,N'Quần kaki xanh rêu',370000),
(10,3,N'Quần kaki nâu',380000),(10,4,N'Quần kaki đen',360000),
(10,5,N'Quần kaki xám',390000),(10,6,N'Quần kaki cargo',420000),
(10,7,N'Quần kaki chinos',400000),(10,8,N'Quần kaki pleated',410000),
(10,2,N'Quần kaki slim xanh',375000),(10,3,N'Quần kaki linen',395000),
-- Quần short (cat 11) × 8
(11,1,N'Quần short thể thao',180000),(11,2,N'Quần short cotton',200000),
(11,3,N'Quần short linen',220000),(11,4,N'Quần short denim',240000),
(11,5,N'Quần short EcoThreads',210000),(11,6,N'Quần short cargo',230000),
(11,7,N'Quần short basic',195000),(11,8,N'Quần short board',250000),
-- Váy ngắn (cat 12) × 10
(12,1,N'Váy ngắn hoa nhí',280000),(12,2,N'Váy ngắn chữ A',310000),
(12,3,N'Váy ngắn tennis',340000),(12,4,N'Váy ngắn denim',320000),
(12,5,N'Váy ngắn linen',295000),(12,6,N'Váy ngắn midi',330000),
(12,7,N'Váy ngắn xếp ly',285000),(12,8,N'Váy ngắn da',380000),
(12,1,N'Váy ngắn hoa cúc',270000),(12,3,N'Váy ngắn pleated',355000),
-- Đầm dài (cat 13) × 10
(13,1,N'Đầm dài hoa mùa hè',380000),(13,2,N'Đầm dài lụa',450000),
(13,3,N'Đầm dài boho',420000),(13,4,N'Đầm dài maxi',480000),
(13,5,N'Đầm dài cotton',400000),(13,6,N'Đầm dài wrap',430000),
(13,7,N'Đầm dài bodycon',460000),(13,8,N'Đầm dài velvet',520000),
(13,2,N'Đầm dài satin',470000),(13,4,N'Đầm dài florals',495000),
-- Mũ & Nón (cat 14) × 6
(14,1,N'Mũ bucket basic',120000),(14,2,N'Nón bóng chày',140000),
(14,3,N'Mũ beanie len',130000),(14,4,N'Nón lưỡi trai',150000),
(14,5,N'Mũ fedora rơm',160000),(14,6,N'Nón snapback',155000),
-- Thắt lưng (cat 15) × 4
(15,1,N'Thắt lưng da bò nam',180000),(15,2,N'Thắt lưng vải',150000),
(15,3,N'Thắt lưng canvas',160000),(15,4,N'Thắt lưng nữ',170000);
GO

-- PRODUCT VARIANTS
DECLARE @p INT = 1;
DECLARE @sizes TABLE (sz NVARCHAR(10), ord INT);
DECLARE @colors TABLE (col NVARCHAR(50), cod VARCHAR(3));
INSERT INTO @sizes VALUES ('S',1),('M',2),('L',3),('XL',4);
INSERT INTO @colors VALUES (N'Trắng','TRG'),(N'Đen','DEN');
WHILE @p <= 20
BEGIN
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           'AT-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod,
           CASE WHEN sz='XL' THEN 20000 ELSE 0 END
    FROM @sizes CROSS JOIN @colors;
    SET @p = @p + 1;
END
GO

DECLARE @p INT = 21;
DECLARE @szShirt TABLE (sz NVARCHAR(10));
DECLARE @colShirt TABLE (col NVARCHAR(50), cod VARCHAR(3));
INSERT INTO @szShirt VALUES ('S'),('M'),('L'),('XL');
INSERT INTO @colShirt VALUES (N'Trắng','TRG'),(N'Xanh nhạt','XN');
WHILE @p <= 32
BEGIN
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           'SM-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod,
           CASE WHEN sz='XL' THEN 20000 ELSE 0 END
    FROM @szShirt CROSS JOIN @colShirt;
    SET @p = @p + 1;
END
GO

DECLARE @p INT = 33;
DECLARE @szJacket TABLE (sz NVARCHAR(10));
DECLARE @colJacket TABLE (col NVARCHAR(50), cod VARCHAR(3));
INSERT INTO @szJacket VALUES ('M'),('L'),('XL'),('XXL');
INSERT INTO @colJacket VALUES (N'Đen','DEN'),(N'Xanh','XAN');
WHILE @p <= 44
BEGIN
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           'AK-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod,
           CASE WHEN sz='XXL' THEN 50000 ELSE 0 END
    FROM @szJacket CROSS JOIN @colJacket;
    SET @p = @p + 1;
END
GO

DECLARE @p INT = 45;
DECLARE @szH TABLE (sz NVARCHAR(10));
DECLARE @colH TABLE (col NVARCHAR(50), cod VARCHAR(3));
INSERT INTO @szH VALUES ('S'),('M'),('L'),('XL');
INSERT INTO @colH VALUES (N'Xám','XAM'),(N'Đen','DEN');
WHILE @p <= 54
BEGIN
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           'HD-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod,
           CASE WHEN sz='XL' THEN 30000 ELSE 0 END
    FROM @szH CROSS JOIN @colH;
    SET @p = @p + 1;
END
GO

DECLARE @p INT = 55;
DECLARE @szJ TABLE (sz NVARCHAR(10));
DECLARE @colJ TABLE (col NVARCHAR(50), cod VARCHAR(3));
INSERT INTO @szJ VALUES ('28'),('30'),('32'),('34');
INSERT INTO @colJ VALUES (N'Xanh nhạt','XN'),(N'Đen','DEN');
WHILE @p <= 69
BEGIN
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           'QJ-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod,
           CASE WHEN sz='34' THEN 30000 ELSE 0 END
    FROM @szJ CROSS JOIN @colJ;
    SET @p = @p + 1;
END
GO

DECLARE @p INT = 70;
DECLARE @sz3  TABLE (sz NVARCHAR(10));
DECLARE @col3 TABLE (col NVARCHAR(50), cod VARCHAR(4));
INSERT INTO @sz3  VALUES ('S'),('M'),('L');
INSERT INTO @col3 VALUES (N'Be','BE'),(N'Xanh rêu','XR');
WHILE @p <= 117
BEGIN
    DECLARE @prefix VARCHAR(4) =
        CASE WHEN @p BETWEEN 70  AND 79  THEN 'QK'
             WHEN @p BETWEEN 80  AND 87  THEN 'QS'
             WHEN @p BETWEEN 88  AND 97  THEN 'VN'
             WHEN @p BETWEEN 98  AND 107 THEN 'DD'
             ELSE 'PK' END;
    INSERT INTO ProductVariants (product_id, size, color, sku, extra_price)
    SELECT @p, sz, col,
           @prefix + '-' + RIGHT('000'+CAST(@p AS VARCHAR),3) + '-' + sz + '-' + cod, 0
    FROM @sz3 CROSS JOIN @col3;
    SET @p = @p + 1;
END
GO

-- INVENTORY
INSERT INTO Inventory (variant_id, warehouse_id, quantity, min_quantity)
SELECT v.variant_id, w.warehouse_id,
       ABS(CHECKSUM(NEWID())) % 91 + 10,
       5
FROM ProductVariants v
CROSS JOIN Warehouses w;
GO

-- CUSTOMERS
INSERT INTO Customers (full_name, email, phone, address, gender, birthday, loyalty_points) VALUES
(N'Nguyễn Thị Hoa',   'hoa@gmail.com',    '0901111001',N'Q1, TP.HCM',          N'Nữ', '1995-03-12',250),
(N'Trần Văn Bình',    'binh@gmail.com',   '0901111002',N'Ba Đình, HN',          N'Nam','1992-07-20',180),
(N'Lê Thị Mai',       'mai@gmail.com',    '0901111003',N'Hải Châu, ĐN',         N'Nữ', '1998-11-05', 90),
(N'Phạm Quốc Hùng',   'hung@gmail.com',   '0901111004',N'Q3, TP.HCM',           N'Nam','1990-01-15',320),
(N'Hoàng Thị Linh',   'linh@gmail.com',   '0901111005',N'Hoàn Kiếm, HN',        N'Nữ', '1997-05-22', 75),
(N'Vũ Minh Khôi',     'khoi@gmail.com',   '0901111006',N'Q7, TP.HCM',           N'Nam','1993-09-30',410),
(N'Đặng Thị Yến',     'yen@gmail.com',    '0901111007',N'Thanh Khê, ĐN',        N'Nữ', '1999-02-14', 60),
(N'Bùi Văn Đức',      'duc@gmail.com',    '0901111008',N'Cầu Giấy, HN',         N'Nam','1988-12-03',200),
(N'Ngô Thị Thanh',    'thanh@gmail.com',  '0901111009',N'Bình Thạnh, HCM',      N'Nữ', '1996-06-18',130),
(N'Dương Văn Tùng',   'tung@gmail.com',   '0901111010',N'Q5, TP.HCM',           N'Nam','1994-04-07',290),
(N'Phan Thị Ngọc',    'ngoc@gmail.com',   '0901111011',N'Liên Chiểu, ĐN',       N'Nữ', '2000-08-25', 45),
(N'Tô Văn Hải',       'hai@gmail.com',    '0901111012',N'Đống Đa, HN',          N'Nam','1991-10-11',160),
(N'Lý Thị Kim Anh',   'kimanh@gmail.com', '0901111013',N'Tân Bình, HCM',        N'Nữ', '1997-03-28',220),
(N'Trương Công Minh', 'minh@gmail.com',   '0901111014',N'Long Biên, HN',         N'Nam','1989-07-16',380),
(N'Cao Thị Thúy',     'thuy@gmail.com',   '0901111015',N'Hòa Vang, ĐN',         N'Nữ', '2001-12-09', 30),
(N'Đinh Văn Phúc',    'phuc@gmail.com',   '0901111016',N'Q10, TP.HCM',          N'Nam','1995-05-04',140),
(N'Huỳnh Thị Diễm',   'diem@gmail.com',   '0901111017',N'Hà Đông, HN',          N'Nữ', '1998-09-13', 70),
(N'Lưu Quang Trung',  'trung@gmail.com',  '0901111018',N'Ngũ Hành Sơn, ĐN',    N'Nam','1993-11-27',190),
(N'Kiều Thị Bích',    'bich@gmail.com',   '0901111019',N'Phú Nhuận, HCM',       N'Nữ', '1996-01-31',110),
(N'Mai Văn Toàn',     'toan@gmail.com',   '0901111020',N'Tây Hồ, HN',           N'Nam','1990-06-08',260),
(N'Trịnh Thị Lan',    'lan@gmail.com',    '0901111021',N'Q2, TP.HCM',           N'Nữ', '1994-08-17', 85),
(N'Đỗ Văn Long',      'long@gmail.com',   '0901111022',N'Đống Đa, HN',          N'Nam','1987-03-25',340),
(N'Hà Thị Thu',       'thu@gmail.com',    '0901111023',N'Ngũ Hành Sơn, ĐN',    N'Nữ', '2002-05-30', 20),
(N'Lương Văn Dũng',   'dung@gmail.com',   '0901111024',N'Q Bình Thạnh, HCM',    N'Nam','1991-12-15',170),
(N'Trần Thị Ngân',    'ngan@gmail.com',   '0901111025',N'Hoàn Kiếm, HN',        N'Nữ', '1999-07-04', 50);

-- STOCK RECEIPTS
INSERT INTO StockReceipts (supplier_id, warehouse_id, created_by, receipt_date, total_amount, note) VALUES
(1,1,6,'2024-01-10',15000000,N'Nhập hàng đầu năm HN'),
(2,2,6,'2024-02-15',22000000,N'Bổ sung tồn kho HCM'),
(3,1,6,'2024-03-20',18500000,N'Nhập hàng xuân hè'),
(1,3,6,'2024-04-05',12000000,N'Nhập kho Đà Nẵng'),
(4,2,6,'2024-05-12',30000000,N'Đơn hàng lớn Q2'),
(2,1,6,'2024-06-01',25000000,N'Nhập hàng hè'),
(3,3,6,'2024-07-10',19000000,N'Bổ sung kho ĐN'),
(5,2,6,'2024-08-05',21000000,N'Nhập hàng thu đông');

INSERT INTO StockReceiptItems (receipt_id, variant_id, quantity, unit_cost) VALUES
(1,1,50,90000),(1,2,50,90000),(1,3,40,90000),(1,4,30,90000),
(2,5,40,90000),(2,9,50,90000),(2,81,60,168000),(2,82,60,168000),
(3,161,50,252000),(3,162,50,252000),(3,163,40,252000),
(4,221,45,270000),(4,222,45,270000),
(5,241,70,198000),(5,242,70,198000),(5,243,50,198000),
(6,261,60,150000),(6,262,60,150000),
(7,1,30,90000),(7,5,30,90000),
(8,81,40,168000),(8,82,40,168000);

-- ORDERS
INSERT INTO Orders (customer_id, created_by, order_date, status, shipping_address, discount_amount, total_amount) VALUES
(1, 3,'2024-01-15 09:30','delivered', N'Q1, TP.HCM',          0,      520000),
(2, 3,'2024-01-18 14:00','delivered', N'Ba Đình, HN',          50000,  830000),
(3, 4,'2024-02-02 10:15','delivered', N'Hải Châu, ĐN',         0,      450000),
(4, 3,'2024-02-10 16:30','delivered', N'Q3, TP.HCM',           0,     1200000),
(5, 4,'2024-02-20 11:00','delivered', N'Hoàn Kiếm, HN',        100000, 680000),
(6, 3,'2024-03-05 09:00','delivered', N'Q7, TP.HCM',           0,      350000),
(7, 5,'2024-03-12 13:45','delivered', N'Thanh Khê, ĐN',        0,      590000),
(8, 3,'2024-03-22 15:20','delivered', N'Cầu Giấy, HN',         0,      960000),
(9, 4,'2024-04-01 10:30','delivered', N'Bình Thạnh, HCM',      50000,  415000),
(10,5,'2024-04-08 14:10','delivered', N'Q5, TP.HCM',           0,      780000),
(11,3,'2024-04-15 09:45','cancelled', N'Liên Chiểu, ĐN',       0,      280000),
(12,4,'2024-05-02 11:30','delivered', N'Đống Đa, HN',          0,     1050000),
(13,5,'2024-05-10 16:00','delivered', N'Tân Bình, HCM',        0,      460000),
(14,3,'2024-05-18 10:00','delivered', N'Long Biên, HN',         150000,1350000),
(15,4,'2024-06-03 13:00','delivered', N'Hòa Vang, ĐN',         0,      320000),
(16,5,'2024-06-12 09:15','shipped',   N'Q10, TP.HCM',          0,      870000),
(17,3,'2024-06-20 14:30','confirmed', N'Hà Đông, HN',          0,      540000),
(18,4,'2024-07-01 10:45','pending',   N'Ngũ Hành Sơn, ĐN',    0,      690000),
(19,5,'2024-07-08 11:00','shipped',   N'Phú Nhuận, HCM',       50000,  950000),
(20,3,'2024-07-15 15:30','pending',   N'Tây Hồ, HN',           0,      420000),
(1, 4,'2024-07-20 09:00','confirmed', N'Q1, TP.HCM',           0,      760000),
(3, 5,'2024-08-01 14:00','pending',   N'Hải Châu, ĐN',         0,      380000),
(5, 3,'2024-08-10 10:30','shipped',   N'Hoàn Kiếm, HN',        0,     1100000),
(2, 4,'2024-08-18 16:00','delivered', N'Ba Đình, HN',           0,      650000),
(6, 5,'2024-08-22 11:00','delivered', N'Q7, TP.HCM',           0,      420000),
(8, 3,'2024-09-01 10:00','delivered', N'Cầu Giấy, HN',         100000, 980000),
(10,4,'2024-09-10 14:30','shipped',   N'Q5, TP.HCM',           0,      730000),
(12,5,'2024-09-15 09:45','confirmed', N'Đống Đa, HN',          0,      560000),
(14,3,'2024-09-20 15:00','pending',   N'Long Biên, HN',         0,     1200000),
(4, 4,'2024-09-25 11:30','delivered', N'Q3, TP.HCM',           50000,  890000);

INSERT INTO OrderItems (order_id, variant_id, quantity, unit_price) VALUES
(1,1,2,150000),(1,9,1,220000),
(2,81,1,420000),(2,161,1,280000),(2,221,1,180000),
(3,241,1,180000),(3,261,1,180000),(3,1,1,150000),
(4,163,1,320000),(4,221,2,180000),(4,83,1,350000),
(5,262,2,165000),(5,162,1,190000),(5,161,1,280000),
(6,3,1,180000),(6,11,1,155000),
(7,242,1,450000),(7,5,1,180000),
(8,83,1,450000),(8,261,1,320000),(8,81,1,420000),
(9,1,1,150000),(9,241,1,120000),(9,162,1,185000),
(10,163,2,320000),(10,161,1,280000),
(11,9,1,220000),(11,5,1,205000),
(12,83,1,450000),(12,261,1,320000),(12,81,2,150000),
(13,242,1,450000),(13,161,1,280000),
(14,163,2,320000),(14,261,2,320000),(14,161,2,280000),
(15,1,1,150000),(15,241,1,140000),
(16,81,1,420000),(16,83,1,450000),
(17,161,2,280000),
(18,163,1,320000),(18,242,1,350000),
(19,83,1,450000),(19,81,1,420000),(19,261,1,320000),
(20,9,1,220000),(20,241,1,200000),
(21,161,1,350000),(21,221,2,180000),
(22,1,1,150000),(22,3,1,180000),
(23,163,2,320000),(23,261,1,320000),(23,81,1,420000),
(24,242,1,450000),(24,161,1,200000),
(25,3,1,180000),(25,11,1,240000),
(26,83,1,450000),(26,163,1,320000),(26,81,1,210000),
(27,81,1,420000),(27,242,1,310000),
(28,261,1,320000),(28,162,1,240000),
(29,163,2,320000),(29,83,1,450000),(29,161,1,130000),
(30,81,1,420000),(30,242,1,470000);

-- PAYMENTS
INSERT INTO Payments (order_id, payment_date, amount, method, status, transaction_ref) VALUES
(1, '2024-01-15',520000, N'Tiền mặt',     'completed',NULL),
(2, '2024-01-18',830000, N'Chuyển khoản', 'completed','TXN20240118'),
(3, '2024-02-02',450000, N'Momo',          'completed','MM20240202'),
(4, '2024-02-10',1200000,N'VNPay',         'completed','VP20240210'),
(5, '2024-02-20',680000, N'Tiền mặt',     'completed',NULL),
(6, '2024-03-05',350000, N'Chuyển khoản', 'completed','TXN20240305'),
(7, '2024-03-12',590000, N'Momo',          'completed','MM20240312'),
(8, '2024-03-22',960000, N'Thẻ',           'completed','CD20240322'),
(9, '2024-04-01',415000, N'Tiền mặt',     'completed',NULL),
(10,'2024-04-08',780000, N'VNPay',         'completed','VP20240408'),
(12,'2024-05-02',1050000,N'Chuyển khoản', 'completed','TXN20240502'),
(13,'2024-05-10',460000, N'Momo',          'completed','MM20240510'),
(14,'2024-05-18',1350000,N'Thẻ',           'completed','CD20240518'),
(15,'2024-06-03',320000, N'Tiền mặt',     'completed',NULL),
(24,'2024-08-18',650000, N'Chuyển khoản', 'completed','TXN20240818'),
(25,'2024-08-22',420000, N'Momo',          'completed','MM20240822'),
(26,'2024-09-01',980000, N'VNPay',         'completed','VP20240901'),
(30,'2024-09-25',890000, N'Thẻ',           'completed','CD20240925');
GO


-- PHẦN 3: 10 VIEWS
-- VIEW 1: Tồn kho theo biến thể & kho
CREATE VIEW vw_InventoryByWarehouse AS
SELECT p.product_id, p.product_name, b.brand_name, c.category_name,
       pv.variant_id, pv.size, pv.color, pv.sku,
       w.warehouse_name, i.quantity, i.min_quantity,
       (p.base_price + pv.extra_price) AS sale_price,
       CASE WHEN i.quantity <= i.min_quantity THEN N'⚠ Sắp hết' ELSE N'✔ Còn hàng' END AS stock_status
FROM Inventory i
JOIN ProductVariants pv ON i.variant_id   = pv.variant_id
JOIN Products       p  ON pv.product_id   = p.product_id
JOIN Brands         b  ON p.brand_id      = b.brand_id
JOIN Categories     c  ON p.category_id   = c.category_id
JOIN Warehouses     w  ON i.warehouse_id  = w.warehouse_id;
GO

-- VIEW 2: Tồn kho thấp (cảnh báo)
CREATE VIEW vw_LowStockAlert AS
SELECT p.product_name, pv.sku, pv.size, pv.color,
       w.warehouse_name, i.quantity, i.min_quantity,
       (i.min_quantity - i.quantity) AS shortage
FROM Inventory i
JOIN ProductVariants pv ON i.variant_id  = pv.variant_id
JOIN Products       p  ON pv.product_id  = p.product_id
JOIN Warehouses     w  ON i.warehouse_id = w.warehouse_id
WHERE i.quantity <= i.min_quantity;
GO

-- VIEW 3: Tổng tồn kho theo sản phẩm
CREATE VIEW vw_TotalStockByProduct AS
SELECT p.product_id, p.product_name, b.brand_name, c.category_name,
       COUNT(DISTINCT pv.variant_id) AS total_variants,
       SUM(i.quantity)               AS total_stock,
       MIN(p.base_price)             AS min_price,
       MAX(p.base_price + pv.extra_price) AS max_price
FROM Products    p
JOIN Brands      b  ON p.brand_id     = b.brand_id
JOIN Categories  c  ON p.category_id  = c.category_id
JOIN ProductVariants pv ON pv.product_id = p.product_id
LEFT JOIN Inventory  i  ON i.variant_id  = pv.variant_id
GROUP BY p.product_id, p.product_name, b.brand_name, c.category_name;
GO

-- VIEW 4: Doanh thu theo ngày
CREATE VIEW vw_DailyRevenue AS
SELECT CAST(o.order_date AS DATE) AS sale_date,
       COUNT(o.order_id)          AS total_orders,
       SUM(o.total_amount)        AS revenue,
       SUM(o.discount_amount)     AS total_discount,
       SUM(o.total_amount) - SUM(o.discount_amount) AS net_revenue
FROM Orders o
WHERE o.status = 'delivered'
GROUP BY CAST(o.order_date AS DATE);
GO

-- VIEW 5: Doanh thu theo tháng
CREATE VIEW vw_MonthlyRevenue AS
SELECT YEAR(o.order_date)  AS yr,
       MONTH(o.order_date) AS mo,
       COUNT(o.order_id)   AS total_orders,
       SUM(o.total_amount) AS revenue,
       AVG(o.total_amount) AS avg_order_value,
       COUNT(DISTINCT o.customer_id) AS unique_customers
FROM Orders o
WHERE o.status = 'delivered'
GROUP BY YEAR(o.order_date), MONTH(o.order_date);
GO

-- VIEW 6: Top sản phẩm bán chạy
CREATE VIEW vw_TopSellingProducts AS
SELECT p.product_id, p.product_name, b.brand_name, c.category_name,
       SUM(oi.quantity)               AS qty_sold,
       SUM(oi.quantity * oi.unit_price) AS revenue,
       COUNT(DISTINCT o.order_id)     AS order_count
FROM OrderItems oi
JOIN Orders         o  ON oi.order_id   = o.order_id
JOIN ProductVariants pv ON oi.variant_id = pv.variant_id
JOIN Products       p  ON pv.product_id  = p.product_id
JOIN Brands         b  ON p.brand_id     = b.brand_id
JOIN Categories     c  ON p.category_id  = c.category_id
WHERE o.status = 'delivered'
GROUP BY p.product_id, p.product_name, b.brand_name, c.category_name;
GO

-- VIEW 7: Chi tiết đơn hàng
CREATE VIEW vw_OrderDetail AS
SELECT o.order_id, o.order_date, o.status,
       c.full_name AS customer_name, c.phone AS customer_phone,
       u.full_name AS staff_name,
       p.product_name, pv.size, pv.color, pv.sku,
       oi.quantity, oi.unit_price,
       oi.quantity * oi.unit_price AS line_total,
       o.discount_amount, o.total_amount, o.shipping_address
FROM Orders      o
JOIN Customers   c  ON o.customer_id = c.customer_id
JOIN Users       u  ON o.created_by  = u.user_id
JOIN OrderItems  oi ON oi.order_id   = o.order_id
JOIN ProductVariants pv ON oi.variant_id  = pv.variant_id
JOIN Products    p  ON pv.product_id  = p.product_id;
GO

-- VIEW 8: Khách hàng VIP
CREATE VIEW vw_TopCustomers AS
SELECT c.customer_id, c.full_name, c.email, c.phone, c.loyalty_points,
       COUNT(o.order_id)    AS total_orders,
       SUM(o.total_amount)  AS total_spent,
       MAX(o.order_date)    AS last_order_date,
       CASE
           WHEN SUM(o.total_amount) >= 5000000 THEN N'VIP Gold'
           WHEN SUM(o.total_amount) >= 2000000 THEN N'VIP Silver'
           ELSE N'Regular'
       END AS customer_tier
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id AND o.status = 'delivered'
GROUP BY c.customer_id, c.full_name, c.email, c.phone, c.loyalty_points;
GO

-- VIEW 9: Phân quyền người dùng (RBAC)
CREATE VIEW vw_UserPermissions AS
SELECT u.user_id, u.full_name, u.email, u.is_active,
       r.role_name, p.module, p.action
FROM Users          u
JOIN Roles          r  ON u.role_id      = r.role_id
JOIN RolePermissions rp ON r.role_id     = rp.role_id
JOIN Permissions    p  ON rp.permission_id = p.permission_id;
GO

-- VIEW 10: Thống kê nhập kho theo nhà cung cấp
CREATE VIEW vw_SupplierStockSummary AS
SELECT s.supplier_id, s.supplier_name, s.contact_person,
       COUNT(DISTINCT sr.receipt_id) AS total_receipts,
       SUM(sri.quantity)             AS total_items_received,
       SUM(sr.total_amount)          AS total_paid,
       MAX(sr.receipt_date)          AS last_receipt_date
FROM Suppliers       s
LEFT JOIN StockReceipts     sr  ON s.supplier_id  = sr.supplier_id
LEFT JOIN StockReceiptItems sri ON sr.receipt_id  = sri.receipt_id
GROUP BY s.supplier_id, s.supplier_name, s.contact_person;
GO

-- PHẦN 4: 10 FUNCTIONS
-- FN 1: Giá biến thể
CREATE FUNCTION dbo.fn_GetVariantPrice(@variant_id INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @price DECIMAL(12,2);
    SELECT @price = p.base_price + pv.extra_price
    FROM ProductVariants pv
    JOIN Products p ON pv.product_id = p.product_id
    WHERE pv.variant_id = @variant_id;
    RETURN ISNULL(@price, 0);
END
GO

-- FN 2: Tổng tồn kho của một variant
CREATE FUNCTION dbo.fn_GetTotalStock(@variant_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @qty INT;
    SELECT @qty = SUM(quantity)
    FROM Inventory
    WHERE variant_id = @variant_id;
    RETURN ISNULL(@qty, 0);
END
GO

-- FN 3: Tổng chi tiêu của khách hàng
CREATE FUNCTION dbo.fn_GetCustomerTotalSpend(@customer_id INT)
RETURNS DECIMAL(14,2)
AS
BEGIN
    DECLARE @total DECIMAL(14,2);
    SELECT @total = SUM(total_amount)
    FROM Orders
    WHERE customer_id = @customer_id AND status = 'delivered';
    RETURN ISNULL(@total, 0);
END
GO

-- FN 4: Đếm số đơn hàng theo trạng thái
CREATE FUNCTION dbo.fn_CountOrdersByStatus(@status NVARCHAR(30))
RETURNS INT
AS
BEGIN
    DECLARE @cnt INT;
    SELECT @cnt = COUNT(*) FROM Orders WHERE status = @status;
    RETURN ISNULL(@cnt, 0);
END
GO

-- FN 5: Xếp hạng khách hàng
CREATE FUNCTION dbo.fn_GetCustomerTier(@customer_id INT)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @spent DECIMAL(14,2) = dbo.fn_GetCustomerTotalSpend(@customer_id);
    RETURN CASE
        WHEN @spent >= 5000000 THEN N'VIP Gold'
        WHEN @spent >= 2000000 THEN N'VIP Silver'
        ELSE N'Regular'
    END;
END
GO

-- FN 6: Doanh thu tháng/năm
CREATE FUNCTION dbo.fn_GetMonthlyRevenue(@year INT, @month INT)
RETURNS DECIMAL(14,2)
AS
BEGIN
    DECLARE @rev DECIMAL(14,2);
    SELECT @rev = SUM(total_amount)
    FROM Orders
    WHERE YEAR(order_date) = @year
      AND MONTH(order_date) = @month
      AND status = 'delivered';
    RETURN ISNULL(@rev, 0);
END
GO

-- FN 7: Kiểm tra tồn kho tại kho cụ thể
CREATE FUNCTION dbo.fn_CheckStock(@variant_id INT, @warehouse_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @qty INT;
    SELECT @qty = quantity
    FROM Inventory
    WHERE variant_id = @variant_id AND warehouse_id = @warehouse_id;
    RETURN ISNULL(@qty, 0);
END
GO

-- FN 8: Tính discount theo loyalty points
CREATE FUNCTION dbo.fn_CalcLoyaltyDiscount(@customer_id INT, @order_amount DECIMAL(12,2))
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @points INT;
    SELECT @points = loyalty_points FROM Customers WHERE customer_id = @customer_id;
    RETURN CASE
        WHEN @points >= 300 THEN @order_amount * 0.10
        WHEN @points >= 100 THEN @order_amount * 0.05
        ELSE 0
    END;
END
GO

-- FN 9: Số ngày kể từ đơn hàng cuối
CREATE FUNCTION dbo.fn_DaysSinceLastOrder(@customer_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @last DATETIME;
    SELECT @last = MAX(order_date)
    FROM Orders
    WHERE customer_id = @customer_id AND status = 'delivered';
    RETURN CASE WHEN @last IS NULL THEN -1 ELSE DATEDIFF(DAY, @last, GETDATE()) END;
END
GO

-- FN 10: Tên đầy đủ SKU
CREATE FUNCTION dbo.fn_GetSKUFullInfo(@sku VARCHAR(60))
RETURNS NVARCHAR(300)
AS
BEGIN
    DECLARE @info NVARCHAR(300);
    SELECT @info = p.product_name + N' | ' + pv.size + N' | ' + pv.color
    FROM ProductVariants pv
    JOIN Products p ON pv.product_id = p.product_id
    WHERE pv.sku = @sku;
    RETURN ISNULL(@info, N'Không tìm thấy');
END
GO


-- PHẦN 5: 10 STORED PROCEDURES
-- PROC 1: Tạo đơn hàng (RESERVE model)
CREATE PROCEDURE sp_CreateOrder
    @customer_id      INT,
    @created_by       INT,
    @shipping_address NVARCHAR(300),
    @discount_amount  DECIMAL(12,2) = 0,
    @note             NVARCHAR(300) = NULL,
    @items_xml        XML,
    @warehouse_id     INT = 1,
    @new_order_id     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @new_order_id = NULL;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO Orders (customer_id, created_by, shipping_address, discount_amount, total_amount, note)
        VALUES (@customer_id, @created_by, @shipping_address, @discount_amount, 0, @note);
        SET @new_order_id = SCOPE_IDENTITY();

        INSERT INTO OrderItems (order_id, variant_id, quantity, unit_price)
        SELECT @new_order_id,
               x.item.value('@vid','INT'),
               x.item.value('@qty','INT'),
               dbo.fn_GetVariantPrice(x.item.value('@vid','INT'))
        FROM @items_xml.nodes('/items/i') AS x(item);

        IF EXISTS (
            SELECT 1
            FROM OrderItems oi
            JOIN Inventory inv ON oi.variant_id = inv.variant_id AND inv.warehouse_id = @warehouse_id
            WHERE oi.order_id = @new_order_id AND inv.quantity < oi.quantity
        )
        BEGIN
            RAISERROR(N'[sp_CreateOrder] Không đủ tồn kho.', 16, 1);
        END

        UPDATE Orders
        SET total_amount = (
            SELECT SUM(quantity * unit_price) FROM OrderItems WHERE order_id = @new_order_id
        ) - @discount_amount
        WHERE order_id = @new_order_id;

        -- RESERVE: trừ kho ngay khi đặt
        UPDATE inv
        SET inv.quantity   -= oi.quantity,
            inv.updated_at  = GETDATE()
        FROM Inventory inv
        JOIN OrderItems oi ON inv.variant_id = oi.variant_id
        WHERE oi.order_id    = @new_order_id
          AND inv.warehouse_id = @warehouse_id;

        UPDATE Orders SET is_stock_reserved = 1 WHERE order_id = @new_order_id;

        INSERT INTO AuditLog (table_name, action, record_id, detail)
        VALUES ('Orders','INSERT',@new_order_id,
                N'Tạo đơn hàng cho customer ' + CAST(@customer_id AS NVARCHAR));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @new_order_id = NULL;
        DECLARE @msg NVARCHAR(2048) = ERROR_MESSAGE();
        DECLARE @sev INT = ERROR_SEVERITY();
        DECLARE @st  INT = ERROR_STATE();
        RAISERROR(@msg, @sev, @st);
    END CATCH
END
GO

-- PROC 2: Thêm item vào đơn
CREATE PROCEDURE sp_AddOrderItem
    @order_id  INT,
    @variant_id INT,
    @quantity  INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @unit_price DECIMAL(12,2);
    SELECT @unit_price = p.base_price + pv.extra_price
    FROM ProductVariants pv JOIN Products p ON pv.product_id = p.product_id
    WHERE pv.variant_id = @variant_id;

    INSERT INTO OrderItems (order_id, variant_id, quantity, unit_price)
    VALUES (@order_id, @variant_id, @quantity, @unit_price);

    UPDATE Orders
    SET total_amount = (SELECT SUM(quantity * unit_price) FROM OrderItems WHERE order_id = @order_id)
                     - discount_amount
    WHERE order_id = @order_id;
END
GO

-- PROC 3: Cập nhật trạng thái đơn hàng (có guard delivered)
CREATE PROCEDURE sp_UpdateOrderStatus
    @order_id   INT,
    @new_status NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    IF @new_status NOT IN ('pending','confirmed','shipping','shipped','delivered','cancelled')
    BEGIN
        RAISERROR(N'Trạng thái không hợp lệ', 16, 1);
        RETURN;
    END

    -- Guard: không cho cancel đơn đã delivered
    IF @new_status = 'cancelled'
       AND EXISTS (
           SELECT 1 FROM Orders
           WHERE order_id = @order_id AND status = 'delivered'
       )
    BEGIN
        RAISERROR(N'Không thể cancel đơn hàng đã giao thành công.', 16, 1);
        RETURN;
    END

    UPDATE Orders SET status = @new_status WHERE order_id = @order_id;
END
GO

-- PROC 4: Nhập kho
CREATE PROCEDURE sp_ReceiveStock
    @supplier_id  INT,
    @warehouse_id INT,
    @created_by   INT,
    @variant_id   INT,
    @quantity     INT,
    @unit_cost    DECIMAL(12,2),
    @note         NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @quantity <= 0
    BEGIN
        RAISERROR(N'Số lượng nhập phải > 0.', 16, 1); RETURN;
    END
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @receipt_id INT;
        INSERT INTO StockReceipts (supplier_id, warehouse_id, created_by, total_amount, note)
        VALUES (@supplier_id, @warehouse_id, @created_by, @quantity * @unit_cost, @note);
        SET @receipt_id = SCOPE_IDENTITY();

        INSERT INTO StockReceiptItems (receipt_id, variant_id, quantity, unit_cost)
        VALUES (@receipt_id, @variant_id, @quantity, @unit_cost);

        INSERT INTO AuditLog (table_name, action, record_id, detail)
        VALUES ('StockReceipts','INSERT',@receipt_id,
                N'Nhập ' + CAST(@quantity AS NVARCHAR) + N' units variant '
                + CAST(@variant_id AS NVARCHAR) + N' vào kho ' + CAST(@warehouse_id AS NVARCHAR));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @errMsg NVARCHAR(2048) = ERROR_MESSAGE();  
        RAISERROR(@errMsg, 16, 1);
    END CATCH
END
GO

-- PROC 5: Tìm kiếm sản phẩm
CREATE PROCEDURE sp_SearchProducts
    @keyword     NVARCHAR(100) = NULL,
    @category_id INT           = NULL,
    @brand_id    INT           = NULL,
    @min_price   DECIMAL(12,2) = NULL,
    @max_price   DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.product_id, p.product_name, b.brand_name, c.category_name,
           p.base_price, p.is_active
    FROM Products p
    JOIN Brands     b ON p.brand_id    = b.brand_id
    JOIN Categories c ON p.category_id = c.category_id
    WHERE (@keyword     IS NULL OR p.product_name LIKE N'%' + @keyword + '%')
      AND (@category_id IS NULL OR p.category_id = @category_id)
      AND (@brand_id    IS NULL OR p.brand_id    = @brand_id)
      AND (@min_price   IS NULL OR p.base_price >= @min_price)
      AND (@max_price   IS NULL OR p.base_price <= @max_price)
      AND p.is_active = 1;
END
GO

-- PROC 6: Báo cáo doanh thu theo khoảng thời gian
CREATE PROCEDURE sp_RevenueReport
    @from_date DATE,
    @to_date   DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(o.order_date AS DATE) AS sale_date,
           COUNT(o.order_id)          AS total_orders,
           SUM(o.total_amount)        AS revenue
    FROM Orders o
    WHERE o.status = 'delivered'
      AND CAST(o.order_date AS DATE) BETWEEN @from_date AND @to_date
    GROUP BY CAST(o.order_date AS DATE)
    ORDER BY sale_date;
END
GO

-- PROC 7: Cập nhật loyalty points sau khi đơn delivered
CREATE PROCEDURE sp_UpdateLoyaltyPoints
    @order_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @customer_id INT, @amount DECIMAL(14,2), @pts INT;
    SELECT @customer_id = customer_id, @amount = total_amount
    FROM Orders WHERE order_id = @order_id AND status = 'delivered';

    IF @customer_id IS NULL RETURN;

    SET @pts = CAST(@amount / 10000 AS INT);
    UPDATE Customers SET loyalty_points = loyalty_points + @pts
    WHERE customer_id = @customer_id;

    INSERT INTO AuditLog (table_name, action, record_id, detail)
    VALUES ('Customers','UPDATE',@customer_id,
            N'Cộng ' + CAST(@pts AS NVARCHAR) + N' điểm loyalty từ đơn ' + CAST(@order_id AS NVARCHAR));
END
GO

-- PROC 8: Lấy tồn kho thấp
CREATE PROCEDURE sp_GetLowStockAlert
    @warehouse_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_LowStockAlert
    WHERE (@warehouse_id IS NULL OR warehouse_name IN (
        SELECT warehouse_name FROM Warehouses WHERE warehouse_id = @warehouse_id
    ))
    ORDER BY shortage DESC;
END
GO

-- PROC 9: Tạo khách hàng mới
CREATE PROCEDURE sp_CreateCustomer
    @full_name NVARCHAR(100),
    @email     NVARCHAR(100) = NULL,
    @phone     VARCHAR(15)   = NULL,
    @address   NVARCHAR(300) = NULL,
    @gender    NVARCHAR(10)  = NULL,
    @birthday  DATE          = NULL,
    @new_id    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Customers (full_name, email, phone, address, gender, birthday)
    VALUES (@full_name, @email, @phone, @address, @gender, @birthday);
    SET @new_id = SCOPE_IDENTITY();
END
GO

-- PROC 10: Dashboard tổng quan
CREATE PROCEDURE sp_GetDashboard
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        (SELECT COUNT(*) FROM Orders WHERE status = 'pending')    AS pending_orders,
        (SELECT COUNT(*) FROM Orders WHERE status = 'shipping')   AS shipping_orders,
        (SELECT COUNT(*) FROM Orders WHERE status = 'delivered'
            AND CAST(order_date AS DATE) = CAST(GETDATE() AS DATE)) AS delivered_today,
        (SELECT SUM(total_amount) FROM Orders WHERE status = 'delivered'
            AND YEAR(order_date) = YEAR(GETDATE())
            AND MONTH(order_date) = MONTH(GETDATE()))              AS revenue_this_month,
        (SELECT COUNT(*) FROM vw_LowStockAlert)                   AS low_stock_alerts,
        (SELECT COUNT(*) FROM Customers)                          AS total_customers;
END
GO


-- PHẦN 6: 12 TRIGGERS

-- TRIGGER 1: Cập nhật Inventory khi nhập kho
CREATE TRIGGER trg_UpdateStockOnReceipt
ON StockReceiptItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    MERGE Inventory AS inv
    USING (
        SELECT i.variant_id, sr.warehouse_id, i.quantity
        FROM inserted i
        JOIN StockReceipts sr ON i.receipt_id = sr.receipt_id
    ) AS src ON inv.variant_id = src.variant_id AND inv.warehouse_id = src.warehouse_id
    WHEN MATCHED THEN
        UPDATE SET inv.quantity = inv.quantity + src.quantity, inv.updated_at = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (variant_id, warehouse_id, quantity) VALUES (src.variant_id, src.warehouse_id, src.quantity);
END
GO

-- TRIGGER 2: Trừ kho khi delivered (chỉ áp dụng khi chưa reserve)
CREATE TRIGGER trg_DeductStockOnDelivered
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM inserted i JOIN deleted d ON i.order_id = d.order_id
        WHERE i.status = 'delivered' AND d.status <> 'delivered'
    ) RETURN;

    -- Chỉ trừ kho nếu chưa reserve (tránh double-deduct)
    UPDATE inv
    SET inv.quantity  -= oi.quantity,
        inv.updated_at = GETDATE()
    FROM Inventory   inv
    JOIN OrderItems  oi ON inv.variant_id  = oi.variant_id
    JOIN inserted    i  ON oi.order_id     = i.order_id
    JOIN Warehouses  w  ON inv.warehouse_id = w.warehouse_id
    WHERE i.status            = 'delivered'
      AND i.is_stock_reserved = 0;  -- chỉ trừ nếu chưa reserve
END
GO

-- TRIGGER 3: Hoàn kho khi cancel
-- Nếu đơn pending chưa reserve → bỏ qua, không cộng sai
CREATE TRIGGER trg_RestoreStockOnCancel
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ fire khi thực sự chuyển sang 'cancelled'
    IF NOT EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted  d ON i.order_id = d.order_id
        WHERE i.status = 'cancelled'
          AND d.status <> 'cancelled'
    ) RETURN;

    -- KEY: chỉ hoàn kho nếu kho đã bị reserve trước đó
    UPDATE inv
    SET inv.quantity   = inv.quantity + oi.quantity,
        inv.updated_at = GETDATE()
    FROM Inventory   inv
    JOIN OrderItems  oi ON inv.variant_id  = oi.variant_id
    JOIN inserted    i  ON oi.order_id     = i.order_id
    WHERE i.status            = 'cancelled'
      AND i.is_stock_reserved = 1;  -- ← CHỈ HOÀN KHI ĐÃ RESERVE 

    --  Reset cờ reserve về 0
    UPDATE o
    SET o.is_stock_reserved = 0
    FROM Orders   o
    JOIN inserted i ON o.order_id = i.order_id
    WHERE i.status = 'cancelled';

    --  Audit log rõ ràng
    INSERT INTO AuditLog (table_name, action, record_id, detail)
    SELECT 'Orders', 'CANCEL', i.order_id,
           CASE i.is_stock_reserved
               WHEN 1 THEN N'Cancel + hoàn kho thành công (reserve=1)'
               ELSE        N'Cancel nhưng chưa reserve — bỏ qua hoàn kho'
           END
    FROM inserted i
    WHERE i.status = 'cancelled';
END
GO

-- TRIGGER 4: Audit log khi tạo đơn
CREATE TRIGGER trg_AuditOrderInsert
ON Orders
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (table_name, action, record_id, detail)
    SELECT 'Orders', 'INSERT', order_id,
           N'Đơn mới | Customer: ' + CAST(customer_id AS NVARCHAR)
           + N' | Total: ' + CAST(total_amount AS NVARCHAR)
    FROM inserted;
END
GO

-- TRIGGER 5: Audit log khi cập nhật đơn
CREATE TRIGGER trg_AuditOrderUpdate
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(status)
        INSERT INTO AuditLog (table_name, action, record_id, detail)
        SELECT 'Orders', 'UPDATE', i.order_id,
               N'Status: ' + d.status + N' → ' + i.status
        FROM inserted i JOIN deleted d ON i.order_id = d.order_id
        WHERE i.status <> d.status;
END
GO

-- TRIGGER 6: Ngăn xóa đơn đã delivered
CREATE TRIGGER trg_PreventDeleteDeliveredOrder
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted WHERE status = 'delivered')
    BEGIN
        RAISERROR(N'Không thể xóa đơn hàng đã giao thành công.', 16, 1);
        RETURN;
    END
    DELETE FROM Orders WHERE order_id IN (SELECT order_id FROM deleted);
END
GO

-- TRIGGER 7: Cập nhật updated_at Inventory
CREATE TRIGGER trg_InventoryUpdatedAt
ON Inventory
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE inv
    SET inv.updated_at = GETDATE()
    FROM Inventory inv
    JOIN inserted  i ON inv.inventory_id = i.inventory_id;
END
GO

-- TRIGGER 8: Audit khi xóa sản phẩm
CREATE TRIGGER trg_AuditProductDelete
ON Products
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditLog (table_name, action, record_id, detail)
    SELECT 'Products', 'DELETE', product_id, N'Xóa sản phẩm: ' + product_name
    FROM deleted;
END
GO

-- TRIGGER 9: Ngăn xóa variant còn tồn kho
CREATE TRIGGER trg_PreventDeleteVariantWithStock
ON ProductVariants
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM Inventory i
        JOIN deleted d ON i.variant_id = d.variant_id
        WHERE i.quantity > 0
    )
    BEGIN
        RAISERROR(N'Không thể xóa biến thể còn tồn kho.', 16, 1);
        RETURN;
    END
    DELETE FROM ProductVariants WHERE variant_id IN (SELECT variant_id FROM deleted);
END
GO

-- TRIGGER 10: Tự động cộng loyalty points khi delivered
CREATE TRIGGER trg_AddLoyaltyPointsOnDelivered
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM inserted i JOIN deleted d ON i.order_id = d.order_id
        WHERE i.status = 'delivered' AND d.status <> 'delivered'
    ) RETURN;

    UPDATE c
    SET c.loyalty_points = c.loyalty_points + CAST(i.total_amount / 10000 AS INT)
    FROM Customers c
    JOIN inserted  i ON c.customer_id = i.customer_id
    WHERE i.status = 'delivered';
END
GO

-- TRIGGER 11: Validate giá trước khi insert/update OrderItems
CREATE TRIGGER trg_ValidateOrderItemPrice
ON OrderItems
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE unit_price <= 0)
    BEGIN
        RAISERROR(N'Đơn giá sản phẩm phải > 0.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END
GO

-- TRIGGER 12: INSTEAD OF UPDATE trên vw_InventoryByWarehouse
CREATE TRIGGER trg_InsteadOfUpdateInventoryView
ON vw_InventoryByWarehouse
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE inv
    SET inv.quantity     = i.quantity,
        inv.min_quantity = i.min_quantity,
        inv.updated_at   = GETDATE()
    FROM Inventory inv
    JOIN inserted  i ON inv.variant_id   = i.variant_id
                    AND inv.warehouse_id = (
                        SELECT warehouse_id FROM Warehouses WHERE warehouse_name = i.warehouse_name
                    );
END
GO

-- PHẦN 7: 10 INDEXES

CREATE INDEX IX_Orders_CustomerId    ON Orders(customer_id);
CREATE INDEX IX_Orders_Status        ON Orders(status);
CREATE INDEX IX_Orders_OrderDate     ON Orders(order_date);
CREATE INDEX IX_OrderItems_OrderId   ON OrderItems(order_id);
CREATE INDEX IX_OrderItems_VariantId ON OrderItems(variant_id);
CREATE INDEX IX_Inventory_VariantId  ON Inventory(variant_id);
CREATE INDEX IX_Inventory_WarehouseId ON Inventory(warehouse_id);
CREATE INDEX IX_Products_CategoryId  ON Products(category_id);
CREATE INDEX IX_Products_BrandId     ON Products(brand_id);
CREATE INDEX IX_ProductVariants_ProductId ON ProductVariants(product_id);
GO


-- KIỂM TRA NHANh

SELECT 'Schema OK' AS result;
SELECT COUNT(*) AS total_products   FROM Products;
SELECT COUNT(*) AS total_variants   FROM ProductVariants;
SELECT COUNT(*) AS total_inventory  FROM Inventory;
SELECT COUNT(*) AS total_orders     FROM Orders;
SELECT COUNT(*) AS total_customers  FROM Customers;
GO
