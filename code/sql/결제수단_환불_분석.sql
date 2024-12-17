# 결제수단 분석

# 1. 결제 수단별 사용 빈도
SELECT
    YEAR(o.order_date) AS OrderYear,
    c.country AS Country,
    CASE
        WHEN c.country IN ('Andorra', 'Australia', 'Austria', 'Bahamas', 'Bahrain', 'Barbados', 'Belgium', 'Brunei Darussalam', 'Canada', 'Cyprus', 'Denmark', 'Finland', 'France', 'Germany', 'Greece', 'Hong Kong SAR', 'Iceland', 'Ireland', 'Israel', 'Italy', 'Japan', 'Kuwait', 'Liechtenstein', 'Luxembourg', 'Macao SAR', 'Malta', 'Monaco', 'Netherlands', 'New Zealand', 'Norway', 'Oman', 'Portugal', 'Qatar', 'San Marino', 'Saudi Arabia', 'Singapore', 'Slovenia', 'South Korea', 'Spain', 'Sweden', 'Switzerland', 'Taiwan', 'United Arab Emirates', 'United Kingdom', 'United States of America') THEN 'High Income'
        WHEN c.country IN ('Albania', 'Antigua and Barbuda', 'Argentina', 'Aruba', 'Belarus', 'Chile', 'Croatia', 'Czech Republic', 'Estonia', 'Hungary', 'Latvia', 'Lithuania', 'Malaysia', 'Poland', 'Russia', 'Seychelles', 'Slovakia', 'Trinidad and Tobago', 'Uruguay', 'Venezuela', 'Algeria', 'Angola', 'Armenia', 'Botswana', 'Burkina Faso', 'Burundi', 'Central African Republic', 'Cote d\'Ivoire', 'Djibouti', 'Faroe Islands', 'Georgia', 'Greenland', 'Guinea-Bissau', 'Kiribati', 'Korea', 'Lao People\'s Democratic Republic', 'Libyan Arab Jamahiriya', 'Mayotte', 'Montenegro', 'Montserrat', 'Nauru', 'Netherlands Antilles', 'Niue', 'Norfolk Island', 'North Macedonia', 'Palau', 'Pitcairn Islands', 'Reunion', 'Saint Barthelemy', 'Saint Helena', 'Saint Martin', 'Saint Pierre and Miquelon', 'Saint Vincent and the Grenadines', 'San Marino', 'Sao Tome and Principe', 'Serbia', 'Slovakia (Slovak Republic)', 'Syrian Arab Republic', 'Timor-Leste', 'Tokelau', 'Turks and Caicos Islands', 'Tuvalu', 'United States Minor Outlying Islands', 'United States Virgin Islands', 'Western Sahara', 'China',
'Colombia', 'Bulgaria', 'Azerbaijan', 'Gibraltar', 'New Caledonia') THEN 'Upper Middle Income'
        WHEN c.country IN ('Afghanistan', 'Angola', 'Bangladesh', 'Benin', 'Bhutan', 'Bolivia', 'Burkina Faso', 'Burundi', 'Cambodia', 'Cameroon', 'Cape Verde', 'Central African Republic', 'Chad', 'Comoros', 'Congo (Dem. Rep.)', 'Congo (Rep.)', 'Costa Rica', 'Côte d\'Ivoire', 'Cuba', 'Djibouti', 'Dominica', 'Dominican Republic', 'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Eswatini', 'Ethiopia', 'Fiji', 'Gabon', 'Gambia', 'Ghana', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 'Honduras', 'India', 'Indonesia', 'Iran', 'Iraq', 'Jamaica', 'Jordan', 'Kazakhstan', 'Kenya', 'Kiribati', 'Kosovo', 'Kyrgyz Republic', 'Lao P.D.R.', 'Lebanon', 'Lesotho', 'Liberia', 'Libya', 'North Macedonia', 'Madagascar', 'Malawi', 'Maldives', 'Mali', 'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Mongolia', 'Montenegro', 'Morocco', 'Mozambique', 'Myanmar', 'Namibia', 'Nauru', 'Nepal', 'Nicaragua', 'Niger', 'Nigeria', 'Pakistan', 'Palau', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Romania', 'Rwanda', 'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 'São Tomé and Príncipe', 'Senegal', 'Serbia', 'Sierra Leone', 'Solomon Islands', 'Somalia', 'South Africa', 'South Sudan', 'Sri Lanka', 'Sudan', 'Suriname', 'Syria', 'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste', 'Togo', 'Tonga', 'Tunisia', 'Turkey', 'Turkmenistan', 'Tuvalu', 'Uganda', 'Ukraine', 'Uzbekistan', 'Vanuatu', 'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe', 'American Samoa', 'Anguilla', 'Antarctica (the territory South of 60 deg S)', 'Belize', 'Bermuda', 'British Indian Ocean Territory (Chagos Archipelago)', 'British Virgin Islands', 'Cayman Islands', 'Christmas Island', 'Cocos (Keeling) Islands', 'Congo', 'Cook Islands', 'Falkland Islands (Malvinas)', 'French Guiana', 'French Polynesia', 'French Southern Territories', 'Heard Island and McDonald Islands', 'Holy See (Vatican City State)', 'Isle of Man', 'Jersey', 'Martinique', 'Puerto Rico', 'Swaziland', 'Guadeloupe', 'Macao', 'South Georgia and the South Sandwich Islands') THEN 'Lower Middle Income'
        ELSE 'Other'
    END AS IncomeGroup,
    CASE
        WHEN pm.payment_method IN ('Cash', 'Debit Card') THEN 'Cash + Debit Card'
        WHEN pm.payment_method IN ('Net Banking', 'UPI') THEN 'Net Banking + UPI'
        ELSE pm.payment_method
    END AS PaymentMethodType,
    SUM(o.amount) AS TotalAmount
FROM
    orders o
JOIN
    customer c ON o.customer_id = c.customer_id
JOIN
    payment_method pm ON o.payment_method_id = pm.payment_method_id
GROUP BY
    OrderYear, Country, IncomeGroup, PaymentMethodType
ORDER BY
    OrderYear, Country, IncomeGroup, PaymentMethodType;


# 2. 제품별 환불 경향
WITH CategoryMappings AS (
  SELECT
    subcategory_id,
    CASE
      WHEN subcategory_name IN ('Smartphones', 'Headphones', 'Cameras', 'Wearables') THEN 'Electronics'
      WHEN subcategory_name IN ('T-Shirts', 'Dresses', 'Jeans', 'Sweaters', 'Activewear') THEN 'Clothing'
      WHEN subcategory_name IN ('Furniture', 'Cookware', 'Bedding', 'Appliances', 'Decor') THEN 'Home & Living'
      WHEN subcategory_name IN ('Fiction', 'Non-Fiction', 'Mystery', 'Biography') THEN 'Books'
      WHEN subcategory_name IN ('Outdoor Clothing', 'Exercise Equipment', 'Camping Gear', 'Sports Shoes', 'Bicycles') THEN 'Outdoor & Sports'
      WHEN subcategory_name IN ('Board Games', 'Action Figures', 'Puzzles', 'Dolls', 'Educational Toys') THEN 'Toys & Games'
      WHEN subcategory_name IN ('Skincare', 'Haircare', 'Makeup', 'Fragrances', 'Personal Hygiene') THEN 'Beauty & Personal Care'
      WHEN subcategory_name IN ('Vitamins', 'Medical Supplies', 'Cleaning Products', 'Pet Care', 'Health Monitors') THEN 'Health & Wellness'
      WHEN subcategory_name IN ('Car Parts', 'Car Accessories', 'Oil & Lubricants', 'Tools', 'Electronics') THEN 'Automotive'
      WHEN subcategory_name IN ('Power Tools', 'Hand Tools', 'Home Security', 'Lighting', 'Paint') THEN 'DIY & Tools'
      WHEN subcategory_name IN ('Office Furniture', 'Stationery', 'Printers', 'Computers', 'Desk Accessories') THEN 'Office Supplies'
      WHEN subcategory_name IN ('Fresh Produce', 'Beverages', 'Snacks', 'Canned Goods', 'Bakery') THEN 'Food & Beverages'
      WHEN subcategory_name IN ('Dog Food', 'Cat Food', 'Pet Toys', 'Grooming', 'Pet Beds') THEN 'Pet Supplies'
      WHEN subcategory_name IN ('Guitars', 'Keyboards', 'Drums', 'Wind Instruments', 'DJ Equipment') THEN 'Music'
      WHEN subcategory_name IN ('Action & Adventure', 'Drama', 'Comedy', 'Science Fiction', 'Documentaries') THEN 'Movies & TV'
      WHEN subcategory_name IN ('Action', 'Adventure', 'Role-Playing', 'Sports', 'Simulation') THEN 'Video Games'
      WHEN subcategory_name IN ('Rings', 'Necklaces', 'Bracelets', 'Earrings', 'Accessories') THEN 'Jewelry'
      WHEN subcategory_name IN ('Laptops', 'Desktops', 'Monitors', 'Networking') THEN 'Computer'
      WHEN subcategory_name IN ('Running Shoes', 'Casual Shoes', 'Boots', 'Sandals', 'Athletic Shoes') THEN 'Shoes'
      WHEN subcategory_name IN ('Analog Watches', 'Digital Watches', 'Smartwatches', 'Luxury Watches', 'Sports Watches', 'Watches') THEN 'Watches'
    END AS custom_category
  FROM subcategory
),
ProductsAndCategories AS (
  SELECT
    p.product_id,
    p.name,
    cm.custom_category
  FROM product p
  JOIN CategoryMappings cm ON p.subcategory_id = cm.subcategory_id
),
ReturnsWithCategories AS (
  SELECT
    r.return_id,
    r.order_id,
    r.product_id,
    r.reason,
    pac.custom_category
  FROM returns r
  JOIN ProductsAndCategories pac ON r.product_id = pac.product_id
),
ProductNames AS (
  SELECT
    product_id,
    name
  FROM product
)
SELECT
  rc.custom_category,
  pn.name AS product_name,
  rc.reason,
  COUNT(*) AS count
FROM ReturnsWithCategories rc
JOIN ProductNames pn ON rc.product_id = pn.product_id
GROUP BY rc.custom_category, pn.name, rc.reason
ORDER BY rc.custom_category, count DESC;

