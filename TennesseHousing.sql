DROP TABLE IF EXISTS #nashville_housing
SELECT *
FROM nashville_housing

--Cleaning the Data
--Standardizing the Date Format

SELECT SaleDate,CAST(SaleDate AS date)
FROM nashville_housing

ALTER TABLE nashville_housing
ADD Sales_Date date

UPDATE nashville_housing
SET Sales_Date = CAST(SaleDate AS date)

--Populating Property address data
SELECT nh1.ParcelID,nh1.PropertyAddress,nh2.ParcelID,nh2.PropertyAddress,ISNULL(nh1.PropertyAddress,nh2.PropertyAddress)
FROM nashville_housing nh1
JOIN nashville_housing nh2
ON nh1.ParcelID = nh2.ParcelID
AND nh1.[UniqueID ] <> nh2.[UniqueID ]
WHERE nh1.PropertyAddress IS NULL


UPDATE nh1
SET PropertyAddress = ISNULL(nh1.PropertyAddress,nh2.PropertyAddress)
FROM nashville_housing nh1
JOIN nashville_housing nh2
ON nh1.ParcelID = nh2.ParcelID
AND nh1.[UniqueID ] <> nh2.[UniqueID ]
WHERE nh1.PropertyAddress IS NULL

--Splitting the address
SELECT PropertyAddress,
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)Property_address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))Property_city
FROM nashville_housing

SELECT *
FROM nashville_housing

ALTER TABLE nashville_housing
ADD Property_address nvarchar(255)

UPDATE nashville_housing
SET Property_address = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE nashville_housing
ADD Property_city nvarchar(255)

UPDATE nashville_housing
SET Property_city = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

SELECT OwnerAddress,
PARSENAME(REPLACE(ownerAddress,',','.'),3)Owner_address,
PARSENAME(REPLACE(ownerAddress,',','.'),2)Owner_city,
PARSENAME(REPLACE(ownerAddress,',','.'),1)Owner_state
FROM nashville_housing

ALTER TABLE nashville_housing
ADD Owner_address nvarchar(255)

UPDATE nashville_housing
SET Owner_street = PARSENAME(REPLACE(ownerAddress,',','.'),3)

ALTER TABLE nashville_housing
ADD Owner_city nvarchar(255)

UPDATE nashville_housing
SET Owner_city = PARSENAME(REPLACE(ownerAddress,',','.'),2)

ALTER TABLE nashville_housing
ADD Owner_state nvarchar(255)

UPDATE nashville_housing
SET Owner_state = PARSENAME(REPLACE(ownerAddress,',','.'),1)

--Changing the Y/N to Yes or No in the SoldAsVacant column 
SELECT DISTINCT SoldAsVacant,COUNT(soldasvacant)
FROM nashville_housing	
GROUP BY SoldAsVacant

SELECT SoldAsVacant,
       CASE 
	   WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM nashville_housing

UPDATE nashville_housing
SET SoldAsVacant = CASE 
				   WHEN SoldAsVacant = 'Y' THEN 'Yes'
				   WHEN SoldAsVacant = 'N' THEN 'No'
				   ELSE SoldAsVacant
				   END
-- Removing Duplicates
-- 104 records found
-- 56373 records left
SELECT *
FROM nashville_housing
;
WITH NASHCTE AS
(SELECT *,
		ROW_NUMBER()
		OVER(PARTITION BY ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference ORDER BY UniqueID)rn
FROM nashville_housing)
DELETE 
FROM NASHCTE
WHERE rn <> 1
 
-- Removing columns that are not relevant
 ALTER TABLE nashville_housing
 DROP COLUMN PropertyAddress,SaleDate,OwnerAddress,TaxDistrict


  SELECT DISTINCT owner_state
 FROM nashville_housing

 SELECT Owner_state,REPLACE(Owner_state,'NULL','TN')
 FROM nashville_housing
 --WHERE owner_state IS NULL


 SELECT Owner_state,
			        CASE 
					WHEN TRIM (Owner_state) IS NULL THEN 'TN'
					ELSE TRIM (Owner_state)
					END
                   FROM nashville_housing

UPDATE nashville_housing
SET owner_state = CASE 
					WHEN TRIM (Owner_state) IS NULL THEN 'TN'
					ELSE TRIM (Owner_state)
					END
                   FROM nashville_housing

UPDATE nashville_housing
SET HalfBath = ISNULL(HalfBath,'0')
FROM nashville_housing

UPDATE nashville_housing
SET FullBath = ISNULL(FullBath,'0')
FROM nashville_housing

UPDATE nashville_housing
SET Bedrooms = ISNULL(Bedrooms,'0')
FROM nashville_housing


-- Filtering records with no values
-- 24118 records
--BEGIN ANALYSIS
DROP TABLE IF EXISTS #nashville_housing

SELECT 
[UniqueID ],ParcelID,LandUse,SalePrice,LegalReference,SoldAsVacant,Acreage,
TotalValue,YearBuilt,Bedrooms,FullBath,HalfBath,Sales_Date,Property_address,Property_city,Owner_state
INTO #nashville_housing
FROM nashville_housing
WHERE LandValue IS NOT NULL
AND BuildingValue IS NOT NULL
AND TotalValue IS NOT NULL
AND Acreage IS NOT NULL
AND YearBuilt IS NOT NULL

-- What is the average sale price of properties across each city?
-- This query selects and calculates average sale prices for each city and compares them to the overall average sale price.

SELECT Property_city,CAST(AVG(SalePrice)AS INT)Average_price_per_city,
(SELECT AVG(SalePrice) FROM #nashville_housing) AS Overall_Average_SalePrice
FROM #nashville_housing
GROUP BY property_city
ORDER BY Average_price_per_city

--Cities where averagesalesprice per city are more than overall average salesprice
--HAVING AVG(SalePrice) > (SELECT AVG(SalePrice) FROM #nashville_housing)
--ORDER BY Average_price_per_city DESC

--Which city has the highest and lowest property salesprice?

SELECT TOP 1 Property_city, MAX(SalePrice) AS Highest_SalePrice
FROM #nashville_housing
GROUP BY Property_city
ORDER BY Highest_SalePrice DESC

SELECT TOP 1 Property_city, MIN(SalePrice) AS Highest_SalePrice
FROM #nashville_housing
GROUP BY Property_city
ORDER BY Highest_SalePrice DESC

--How many properties are sold as "Vacant" and how many are not sold as "Vacant" in the dataset?

SELECT SoldAsVacant,COUNT (SoldAsVacant) Count_Sold_as_Vacant
FROM #nashville_housing
GROUP BY SoldAsVacant

--Are there any seasonal patterns in house listings or sales? e.g do more houses get sold during a specific season?

SELECT
    DATENAME(MONTH, Sales_Date) AS Sale_Month,
    COUNT(*) AS Number_of_Sales
FROM #nashville_housing
GROUP BY DATENAME(MONTH, Sales_Date)
ORDER BY Number_of_Sales DESC

-- What is the total sale revenue for each year?

SELECT
    YEAR(Sales_Date) AS Sale_Year,
    CAST(SUM(SalePrice)AS INT) AS Total_Sale_Price
FROM #nashville_housing
GROUP BY YEAR(Sales_Date)
ORDER BY Total_Sale_Price DESC

-- What are the annual revenue trends, is there any significant growth or decline during this period?
WITH YearlyRevenue AS (
    SELECT
        YEAR(Sales_Date) AS Sale_Year,
        SUM(SalePrice) AS Total_Revenue
    FROM #nashville_housing
    GROUP BY YEAR(Sales_Date)
)

SELECT
    Sale_Year,
    Total_Revenue,
    LAG(Total_Revenue) OVER (ORDER BY Sale_Year) AS Previous_Year_Revenue,
    ((Total_Revenue - LAG(Total_Revenue) OVER (ORDER BY Sale_Year)) * 100.0 / LAG(Total_Revenue) OVER (ORDER BY Sale_Year)) AS Percentage_Growth
FROM YearlyRevenue
ORDER BY Sale_Year
