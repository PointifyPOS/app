import 'package:pointify/models/batch.dart';
import 'package:pointify/models/bundleitem.dart';
import 'package:pointify/models/productcategory.dart';
import 'package:pointify/models/shop.dart';
import 'package:pointify/models/supplier.dart';

import '../screens/product/create_product.dart';

class ProductDisplay {
  String? name;
  String? sId;
  String? image;
  String? type;
  String? measureUnit;

  double? buyingPrice;
  double? sellingPrice;
  double? minSellingPrice;

  double? quantity;

  String? status;

  int? reorderLevel;

  double? maxDiscount;

  Supplier? supplierId;
  String? supplierName;

  ProductCategory? productCategoryId;
  String? productCategoryName;

  String? description;
  String? expiryDate;
  String? manufacturer;
  String? barcode;

  double? wholesalePrice;
  double? dealerPrice;

  List<CustomImage>? images;

  Attendant? attendantId;

  bool? bundle;
  bool? virtual;
  bool? taxable;
  bool? manageByPrice;

  ProductDisplay({
    this.name,
    this.sId,
    this.image,
    this.type,
    this.measureUnit,
    this.buyingPrice,
    this.sellingPrice,
    this.minSellingPrice,
    this.quantity,
    this.status,
    this.reorderLevel,
    this.maxDiscount,
    this.supplierId,
    this.supplierName,
    this.productCategoryId,
    this.productCategoryName,
    this.description,
    this.expiryDate,
    this.manufacturer,
    this.barcode,
    this.wholesalePrice,
    this.dealerPrice,
    this.images,
    this.attendantId,
    this.bundle,
    this.virtual,
    this.taxable,
    this.manageByPrice,
  });

  ProductDisplay.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    sId = json['_id'];

    image = json['image'];

    type = json['productType'] ?? json['type'] ?? "product";

    measureUnit = json['measure'] ?? json['measureUnit'];

    buyingPrice =
        json['buyingPrice'] == null ? 0.0 : json['buyingPrice'].toDouble();

    sellingPrice =
        json['sellingPrice'] == null ? 0.0 : json['sellingPrice'].toDouble();

    minSellingPrice = json['minSellingPrice'] == null
        ? 0.0
        : json['minSellingPrice'].toDouble();

    quantity = json['quantity'] == null ? 0.0 : json['quantity'].toDouble();

    status = json['status'];

    reorderLevel = json['reorderLevel'] == null
        ? 0
        : int.tryParse(json['reorderLevel'].toString());

    maxDiscount =
        json['maxDiscount'] == null ? 0.0 : json['maxDiscount'].toDouble();

    supplierId =
        json['supplierId'] != null && json['supplierId'] is String == false
            ? Supplier.fromJson(json['supplierId'])
            : null;

    supplierName = json['supplierName'];

    productCategoryId = json['productCategoryId'] != null &&
            json['productCategoryId'] is String == false
        ? ProductCategory.fromJson(json['productCategoryId'])
        : null;

    productCategoryName = json['productCategoryName'];

    description = json['description'];

    expiryDate = json['expiryDate'];

    manufacturer = json['manufacturer'];

    barcode = json['barcode'];

    wholesalePrice = json['wholesalePrice'] == null
        ? 0.0
        : json['wholesalePrice'].toDouble();

    dealerPrice =
        json['dealerPrice'] == null ? 0.0 : json['dealerPrice'].toDouble();

    images = json["images"] == null ||
            json["images"].isEmpty ||
            json["images"] is String
        ? []
        : List<CustomImage>.from(
            json["images"].map(
              (x) => CustomImage(
                imgType: ImageType.network,
                path: x ?? "",
              ),
            ),
          );

    if (json['attendantId'] != null && json['attendantId'] is String == false) {
      attendantId = Attendant.fromJson(json['attendantId']);
    }

    bundle = json['bundle'] ?? false;
    virtual = json['virtual'] ?? false;

    taxable = json['taxable'] == 1 || json['taxable'] == true ? true : false;

    manageByPrice = json['manageByPrice'] ?? false;
  }

  factory ProductDisplay.fromProduct(Product product) {
    return ProductDisplay(
      sId: product.sId,
      name: product.name,
      image: product.images != null && product.images!.isNotEmpty
          ? product.images!.first.path
          : null,
      images: product.images,
      type: product.type,
      measureUnit: product.measureUnit,
      buyingPrice: product.buyingPrice,
      sellingPrice: product.sellingPrice,
      minSellingPrice: product.minSellingPrice,
      quantity: product.quantity,
      status: product.status,
      reorderLevel: product.reorderLevel,
      maxDiscount: product.maxDiscount,
      supplierId: product.supplierId,
      supplierName: product.supplierId?.name,
      productCategoryId: product.productCategoryId,
      productCategoryName: product.productCategoryId?.name,
      description: product.description,
      expiryDate: product.expiryDate,
      manufacturer: product.manufacturer,
      barcode: product.barcode,
      wholesalePrice: product.wholesalePrice,
      dealerPrice: product.dealerPrice,
      attendantId: product.attendantId,
      bundle: product.bundle,
      virtual: product.virtual,
      taxable: product.taxable,
      manageByPrice: product.manageByPrice,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "_id": sId,
      "name": name,
      "image": image,
      "type": type,
      "measureUnit": measureUnit,
      "buyingPrice": buyingPrice,
      "sellingPrice": sellingPrice,
      "minSellingPrice": minSellingPrice,
      "quantity": quantity,
      "status": status,
      "reorderLevel": reorderLevel,
      "maxDiscount": maxDiscount,
      "supplierId": supplierId?.toJson(),
      "supplierName": supplierName,
      "productCategoryId": productCategoryId?.toJson(),
      "productCategoryName": productCategoryName,
      "description": description,
      "expiryDate": expiryDate,
      "manufacturer": manufacturer,
      "barcode": barcode,
      "wholesalePrice": wholesalePrice,
      "dealerPrice": dealerPrice,
      "bundle": bundle,
      "virtual": virtual,
      "taxable": taxable,
      "manageByPrice": manageByPrice,
      "attendantId": attendantId?.toJson(),
      "images": images?.map((e) => e.path).toList(),
    };
  }

  Product toProduct() {
    return Product(
      sId: sId,
      images: images ?? [],
      name: name,
      manufacturer: manufacturer,
      expiryDate: expiryDate,
      manageByPrice: manageByPrice,
      status: status,
      taxable: taxable,
      buyingPrice: buyingPrice,
      sellingPrice: sellingPrice,
      minSellingPrice: minSellingPrice,
      virtual: virtual,
      quantity: quantity,
      bundle: bundle,
      maxDiscount: maxDiscount,
      reorderLevel: reorderLevel,
      barcode: barcode,
      productCategoryId: productCategoryId,
      measureUnit: measureUnit,
      supplierId: supplierId,
      description: description,
      type: type,
      dealerPrice: dealerPrice,
      wholesalePrice: wholesalePrice,
      attendantId: attendantId,
    );
  }
}

class Product {
  List<CustomImage>? images;
  String? sId;
  List<Batch>? batches;
  List<BundleItem>? bundleItems;
  String? inventoryId;
  String? type;
  String? name;
  String? manufacturer;
  double? buyingPrice;
  int? totalSoldQty;
  int? salesCount;
  double? sellingPrice;
  double? wholesalePrice;
  double? dealerPrice;
  double? minSellingPrice;
  String? measureUnit;
  double? quantity;
  int? lastCount;
  double? maxDiscount;
  int? reorderLevel;
  ProductCategory? productCategoryId;
  String? barcode;
  String? expiryDate;
  Supplier? supplierId;
  Shop? shop;
  String? description;
  String? uploadImage;
  Attendant? attendantId;
  String? lastcoundate;
  String? date;
  String? status;
  bool? bundle;
  bool? virtual;
  bool? taxable;
  bool? manageByPrice;

  Product(
      {this.sId,
      this.images = const [],
      this.name,
      this.manufacturer,
      this.expiryDate,
      this.manageByPrice,
      this.status,
      this.totalSoldQty,
      this.salesCount,
      this.taxable,
      this.batches,
      this.buyingPrice,
      this.sellingPrice,
      this.minSellingPrice,
      this.virtual,
      this.quantity,
      this.bundle,
      this.inventoryId,
      this.lastCount,
      this.maxDiscount,
      this.reorderLevel,
      this.barcode,
      this.productCategoryId,
      this.measureUnit,
      this.supplierId,
      this.shop,
      this.description,
      this.uploadImage,
      this.type,
      this.dealerPrice,
      this.wholesalePrice,
      this.attendantId,
      this.lastcoundate,
      this.date});

  Product.fromJson(Map<String, dynamic> json) {
    images = json["images"] == null ||
            json["images"].isEmpty ||
            json["images"] is String
        ? null
        : List<CustomImage>.from(json["images"].map(
            (x) => CustomImage(imgType: ImageType.network, path: x ?? "")));
    sId = json['_id'];
    type = json['productType'] ?? "product";
    totalSoldQty = json['totalSoldQty'] is int
        ? double.parse(json['totalSoldQty'].toString()).toInt()
        : json['totalSoldQty'] ?? 0;
    salesCount = json['salesCount'] is int
        ? double.parse(json['salesCount'].toString()).toInt()
        : json['salesCount'] ?? 0;
    batches = json['batches'] == null
        ? []
        : List<Batch>.from(json['batches'].map((x) => Batch.fromJson(x)));
    bundleItems = json['bundleItems'] == null
        ? []
        : List<BundleItem>.from(
            json['bundleItems'].map((x) => BundleItem.fromJson(x)));
    inventoryId = json['inventoryId'] ?? "";
    manufacturer = json['manufacturer'] ?? "";
    manageByPrice = json['manageByPrice'] ?? false;
    name = json['name'];
    wholesalePrice = json['wholesalePrice'] == null
        ? 0.0
        : json['wholesalePrice'].toDouble();
    dealerPrice =
        json['dealerPrice'] == null ? 0.0 : json['dealerPrice'].toDouble();
    barcode = json['barcode'];
    expiryDate = json['expiryDate'] ?? '';
    taxable = json['taxable'] == 1 || json['taxable'] == true
        ? true
        : json['taxable'] == false
            ? false
            : null;
    buyingPrice =
        json['buyingPrice'] == null ? 0.0 : json['buyingPrice'].toDouble();
    sellingPrice =
        json['sellingPrice'] == null ? 0.0 : json['sellingPrice'].toDouble();
    minSellingPrice = json['minSellingPrice'] == null
        ? 0.0
        : json['minSellingPrice'].toDouble();
    quantity = json['quantity'] == null ? 0.0 : json['quantity'].toDouble();

    maxDiscount =
        json['maxDiscount'] == null ? 0.0 : json['maxDiscount'].toDouble();

    reorderLevel = json['reorderLevel'];
    if (json['productCategoryId'] != null &&
        json['productCategoryId'] is String == false) {
      productCategoryId = ProductCategory.fromJson(json['productCategoryId']);
    }
    if (json['supplierId'] != null && json['supplierId'] is String == false) {
      supplierId = Supplier.fromJson(json['supplierId']);
    }
    if (json['attendantId'] != null && json['attendantId'] is String == false) {
      attendantId = Attendant.fromJson(json['attendantId']);
    }
    if (json['shopId'] != null && json['shopId'] is String == false) {
      shop = Shop.fromJson(json['shopId']);
    }
    status = json['status'] ?? '';
    virtual = json['virtual'] ?? false;
    bundle = json['bundle'] ?? false;
    lastCount = json['lastCount'] ?? 0;
    measureUnit = json['measure'] ?? "";
    description = json['description'];
    uploadImage = json['uploadImage'];
    lastcoundate = json['lastcoundate'] ?? json['date'];
    date = json['date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['name'] = name;
    data['buyingPrice'] = buyingPrice;
    data['buyingPrice'] = buyingPrice;
    data['sellingPrice'] = sellingPrice;
    data['minSellingPrice'] = minSellingPrice;
    data['quantity'] = quantity;
    data['maxDiscount'] = maxDiscount;
    data['reorderLevel'] = reorderLevel;
    if (productCategoryId != null) {
      data['productCategoryId'] = productCategoryId!.toJson();
    }
    data['measure'] = measureUnit;
    if (supplierId != null) {
      data['supplierId'] = supplierId!.toJson();
    }
    if (shop != null) {
      data['shopId'] = shop!.toJson();
    }
    data['description'] = description;
    data['uploadImage'] = uploadImage;
    if (attendantId != null) {
      data['attendantId'] = attendantId!.toJson();
    }
    data['date'] = date;
    data['lastcoundate'] = lastcoundate;
    return data;
  }

  //get the oldest (by createdAt) batch buying price
  // String? getBuyingPrice() {
  //   if (batches!.isNotEmpty) {
  //     List<Batch> batches = this.batches!;
  //     double totalQty = batches.fold(0, (p, b) => p + b.quantity!);
  //     if (totalQty == 0) return buyingPrice?.toStringAsFixed(2);
  //     if (totalQty < quantity!) return buyingPrice?.toStringAsFixed(2);
  //     batches.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
  //     return batches.first.buyingPrice!.toStringAsFixed(2);
  //   } else {
  //     return buyingPrice?.toStringAsFixed(2);
  //   }
  // }
}

bool isInteger(num value) => value is int || value == value.roundToDouble();

class Attendant {
  String? sId;
  String? username;

  Attendant({this.sId, this.username});

  Attendant.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    username = json['username'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['username'] = username;
    return data;
  }
}
