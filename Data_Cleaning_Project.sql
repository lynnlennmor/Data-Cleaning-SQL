
 /*
---------------------------------------
 DATA CLEANING ON HOUSING DATA IN SQL 
---------------------------------------
 */

-- STANDARDIZE/CHANGE DATE FORMAT

-- How we want the date to look like
SELECT
	SaleDate,
	CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing AS nh;

-- Changing the data type from DATETIME to DATE in order to do the convertion to DATE
ALTER TABLE dbo.NashvilleHousing
ALTER COLUMN SaleDate DATE;

-- Converting the data 
UPDATE dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);


-- POPULATE PROPERTY ADDRESS DATA (NULL/MISSING DATA)
-- With data such as a Property Address we know that we can most likely populate it somehow, because it will not really change.

-- By using a Self-join we can to check if duplicates rows (with different Unique IDs) have a PropertyAddress
-- Using the IFNULL statement to update NULL values in PropertyAddress with the value of the duplicate row's PropertyAddress.
SELECT
	nh.ParcelID,
	nh.PropertyAddress,
	nh_2.ParcelID,
	nh_2.PropertyAddress,
	ISNULL(nh.PropertyAddress, nh_2.PropertyAddress) AS new_property_address
FROM PortfolioProject.dbo.NashvilleHousing AS nh
JOIN PortfolioProject.dbo.NashvilleHousing AS nh_2
	ON nh.ParcelID = nh_2.ParcelID
	AND nh.[UniqueID ] <> nh_2.[UniqueID ]
WHERE nh.PropertyAddress IS NULL;

-- Updating and populating the missing PropertyAddresses
UPDATE nh
SET PropertyAddress = ISNULL(nh.PropertyAddress, nh_2.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing AS nh
JOIN PortfolioProject.dbo.NashvilleHousing AS nh_2
	ON nh.ParcelID = nh_2.ParcelID
	AND nh.[UniqueID ] <> nh_2.[UniqueID ]
WHERE nh.PropertyAddress IS NULL;


-- BREAKING OUT ADDRESS INTO INDIVIUAL COLUMNS (ADDRESS, CITY, STATE)

-- For the PropertyAddress column

-- How we want the data to look
-- Using Substring and Charindex to split the data
SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM PortfolioProject.dbo.NashvilleHousing AS nh;

-- Alternative easier query
SELECT 
	PARSENAME(REPLACE(PropertyAddress, ',', '.'), 2) AS Address,
	PARSENAME(REPLACE(PropertyAddress, ',', '.'), 1) AS City
FROM PortfolioProject.dbo.NashvilleHousing AS nh;

-- Creating new columns
ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitAddress VARCHAR(255);

ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitCity VARCHAR(255);

-- Updating new columns with new data
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1,LEN(PropertyAddress));

-- Double checking the new data
SELECT
	PropertySplitAddress,
	PropertySplitCity
FROM PortfolioProject.dbo.NashvilleHousing AS nh;

-- For the OwnerAdress column

-- Parsing the address into three separate columns by splitting them based on the delimiter.
-- REPLACE is used because for PARSENAME to work we need to convert the ',' to a '.'
-- How we want the data to look
SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM PortfolioProject.dbo.NashvilleHousing AS nh;

-- Creating new columns
ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitAddress VARCHAR(255);

ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitCity VARCHAR(255);

ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitState VARCHAR(255);

-- Updating new columns with new data, similar to what we did with the PropertyAddress
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Double checking the data
SELECT 
	OwnerSplitAddress,
	OwnerSplitCity,
	OwnerSplitState
FROM PortfolioProject.dbo.NashvilleHousing AS nh;


-- STANDARDIZE THE DATA BY CHANING 'Y' & 'N' to 'Yes' and 'NO' IN "Sold as Vacant" COLUMN

-- There are a few values in SoldAsVacant that have Y an N instead of Yes and No which we want to change.
-- We can do that with a CASE statement
-- How we want the data to look
SELECT
	SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END as SoldAsVacant_new
FROM PortfolioProject.dbo.NashvilleHousing AS nh;

-- Updating the data
UPDATE NashvilleHousing
SET SoldAsVacant = 
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END;

-- Checking that the Update worked
SELECT 
	DISTINCT SoldAsVacant
FROM PortfolioProject.dbo.NashvilleHousing AS nh;


-- REMOVE DUPLICATES
-- Standard practice is to not fully delete the raw data and instead use a temp_table and use that to remove duplicates.
-- But this is to show the process of how to remove duplicates

-- We can find the duplicate rows by using a PARTITION BY statement and using a CTE in order to later delete the unwated rows
	-- We want to parition on fields that must/should match to be considered a duplicate row
WITH CTE AS (
SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID ) AS row_num
FROM PortfolioProject.dbo.NashvilleHousing AS nh
)

-- Checking all the duplicate rows.
SELECT *
FROM CTE
WHERE row_num > 1;

-- Deleting the duplicated rows
DELETE
FROM CTE
WHERE row_num > 1;


-- DELETE UNUSED COLUMNS

-- Same as the above, standard practice is not to remove or change the raw data.

SELECT
	*
FROM PortfolioProject.dbo.NashvilleHousing AS nh

-- Deleting unwanted columns.
ALTER TABLE PortfolioProject.dbo.NashvilleHousing

DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;
