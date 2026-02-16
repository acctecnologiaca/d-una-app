enum ProductSortOption {
  priceAsc,
  priceDesc,
  quantityAsc,
  quantityDesc,
  nameAZ,
  nameZA;

  String get label {
    switch (this) {
      case ProductSortOption.priceAsc:
        return 'Menor precio';
      case ProductSortOption.priceDesc:
        return 'Mayor precio';
      case ProductSortOption.quantityAsc:
        return 'Menor cantidad de productos';
      case ProductSortOption.quantityDesc:
        return 'Mayor cantidad de productos';
      case ProductSortOption.nameAZ:
        return 'Nombre (A-Z)';
      case ProductSortOption.nameZA:
        return 'Nombre (Z-A)';
    }
  }
}
