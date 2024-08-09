-- Cleaning Data in SQL Query:

Use PortfolioProject

Select *
From NashvilleHousing

--------------------------------------------------------------------------------

-- Chuẩn hóa định dạng ngày tháng:

Alter Table NashvilleHousing
	Alter Column SaleDate date
-- Câu lệnh trên thay đổi định dạng cột SaleDate từ datetime sang date.

--------------------------------------------------------------------------------

-- Điền dữ liệu địa chỉ của bất động sản:

Select *
From NashvilleHousing
--Where PropertyAddress is null
Order By ParcelID

-- ParcelID thường gắn với địa chỉ của bất động sản giúp xác định vị trí chính xác.
-- Khi truy vấn ParcelID mà PropertyAddress để trống thì có thể tự động thêm thông tin địa chỉ.
-- Đoạn code này sử dụng truy vấn self join bảng NashvilleHousing với chính nó.
-- Tìm các hàng trong bảng có cột PropertyAddress là null dựa vào cột ParcelID có trong bảng a, 
-- sau đó tìm kiếm ParcelID ở bảng b với điều kiện UniqueID của 2 bảng phải khác nhau để lấy giá trị PropertyAddress từ bảng b điền giá trị vào bảng a.

Select a.ParcelID, b.ParcelID, a.PropertyAddress, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From NashvilleHousing a
Join NashvilleHousing b
	On a.ParcelID = b.ParcelID
	And a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From NashvilleHousing a
Join NashvilleHousing b
	On a.ParcelID = b.ParcelID
	And a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

--------------------------------------------------------------------------------

-- Chia cột Address thành các cột riêng lẻ (Address, City, State):

Select PropertyAddress
From NashvilleHousing

-- VD: Để tách "5204 ALOUISIANA AVE, NASHVILLE" thành địa chỉ: 5204 ALOUISIANA AVE, thành phố: NASHVILLE
-- Sử dụng hàm Substring để trích xuất chuỗi địa chỉ trong cột PropertyAddress bắt đầu từ vị trí đầu tiên
-- Sử dụng hàm Charindex để trả về vị trí ký tự đầu tiên là dấu ',' sau đó là -1 để không lấy dấu ',' làm số lượng của chuỗi

Select 
	Substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
From NashvilleHousing

Alter Table NashvilleHousing
	Add PropertySplitAddress nvarchar(255);

Update NashvilleHousing
Set PropertySplitAddress = Substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

Alter Table NashvilleHousing
	Add PropertySplitCity nvarchar(255);

Update NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

Select *
From NashvilleHousing

Select OwnerAddress
From NashvilleHousing

-- VD: Tách chuỗi "5204 A LOUISIANA AVE, NASHVILLE, TN" trong cột OwnerAddress thành Address, City, State
-- Sử dụng hàm Parsename để tách các phần trong chuỗi theo dấu chấm
-- Sử dụng hàm Replace để thay thế các dấu phẩy trong chuỗi thành dấu chấm.

Select 
		PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
		PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
		PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From NashvilleHousing

Alter Table NashvilleHousing
	Add OwnerSplitAddress nvarchar(255);

Update NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

Alter Table NashvilleHousing
	Add OwnerSplitCity nvarchar(255);

Update NashvilleHousing
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

Alter Table NashvilleHousing
	Add OwnerSplitState nvarchar(255);

Update NashvilleHousing
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

Select *
From NashvilleHousing

--------------------------------------------------------------------------------

-- Chuyển Y và N sang Yes và No trong cột SoldAsVacant:

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousing
Group By SoldAsVacant
Order By 2

Select SoldAsVacant,
		Case When SoldAsVacant = 'Y' Then 'Yes'
			When SoldAsVacant = 'N' Then 'No'
		Else SoldAsVacant
		End
From NashvilleHousing

Update NashvilleHousing
Set SoldAsVacant = Case When SoldAsVacant = 'Y' Then 'Yes'
						When SoldAsVacant = 'N' Then 'No'
					Else SoldAsVacant
					End

--------------------------------------------------------------------------------

-- Loại bỏ giống nhau:
-- Mục đích là để loại bỏ những nội dung giống nhau không cần thiết:

With RowNumCTE as(
Select *,
	ROW_NUMBER() OVER (
	Partition By ParcelID,
				PropertyAddress,
				SaleDate,
				SalePrice,
				LegalReference
				Order By UniqueID
				) row_num

From NashvilleHousing
)
--Delete
Select *
From RowNumCTE
Where row_num > 1
Order By PropertyAddress

Select *
From NashvilleHousing

--------------------------------------------------------------------------------

-- Xóa các cột không dùng đến

Alter Table NashvilleHousing
Drop Column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

Select *
From NashvilleHousing