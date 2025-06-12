const homePage = "Home";
const shopsPage = "Shops";
const attendantPage = "Attendants";
const profitsPage = "Profit & Expenses";
const salesPage = "Sales & orders";
const oneSignalAppID = "e3712d02-5635-485c-abd8-7c8f97f6c137";

const String androidKey = 'AIzaSyAhhiH3PrL9td9IGJWfpK3CXnU3gtsIYHY';
const String iosKey = 'AIzaSyAhhiH3PrL9td9IGJWfpK3CXnU3gtsIYHY';
const profilePage = "Profile";
const demolink = "https://pointify-front-end.vercel.app/";
const authPage = "Log Out";
var imageplaceholder = "assets/images/image_placeholder.jpg";
const allowSubscription = true;
var deepLinkUriPrefix = "https://pospointify.page.link/";
var packagename = "com.pointify.com";
Map<String, dynamic> settingsData = {'offlineEnabled': false};
const appstoreId = '6456891671';
const androidLink =
    'https://play.google.com/store/apps/details?id=com.pointify.com';
const iosLink = 'https://apps.apple.com/tr/app/pointify-pos/id6456891671';
var stripePublishKey =
    "pk_live_51LRzYODw17FV5y60pUv8GOcGsdduO6KixMR70u8fTIZX4JvCdu2Oyuhe3MTjBgpAtCnvmZZSA9SeyM4eswvpRw4500g3AuyPJG";

class Constants {
  static final RegExp emailValidatorRegExp =
      RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  var sortOrder = [
    "All",
    "Highest Stock Balance",
    "Out Of Stock",
    "Running Low",
    "Expiry Date",
    "Highest Buying Price",
    "Highest Selling Price",
    "Processed",
    "Processing"
  ];
  var productionOrder = ["All", "Processed", "Processing","Raw"];
  var sortBatch = [
    "All",
    "Date Added",
    "Out Of Stock",
    "Running Low",
    "Expiry Date",
    "Highest Buying Price",
  ];
  var sortOrderList = [
    "all",
    "quantity",
    "outofstock",
    "runninglow",
    "expirydate",
    "highestbuying",
    "highestselling"
  ];
  var sortOrderCaunt = [
    "All",
    "Counted Today",
    "Counted By Date",
    "Not Counted Today",
    "Never Counted"
  ];
  var sortOrderCauntList = [
    "all",
    "countedtoday",
    "counteddate",
    "notcountedtoday",
    "nevercounted"
  ];

  static final currenciesData = [
    "KES",
    "USD",
    "CAD",
    "EUR",
    "AED",
    "AFN",
    "ALL",
    "AMD",
    "ARS",
    "AUD",
    "AZN",
    "BAM",
    "BDT",
    "BGN",
    "BHD",
    "BIF",
    "BND",
    "BOB",
    "BRL",
    "BWP",
    "BYN",
    "BZD",
    "CDF",
    "CHF",
    "CLP",
    "CNY",
    "COP",
    "CRC",
    "CVE",
    "CZK",
    "DJF",
    "DKK",
    "DOP",
    "DZD",
    "EEK",
    "EGP",
    "ERN",
    "ETB",
    "GBP",
    "GEL",
    "GHS",
    "GNF",
    "GTQ",
    "HKD",
    "HNL",
    "HRK",
    "HUF",
    "IDR",
    "ILS",
    "INR",
    "IQD",
    "IRR",
    "ISK",
    "JMD",
    "JOD",
    "JPY",
    "KHR",
    "KMF",
    "KRW",
    "KWD",
    "KZT",
    "LBP",
    "LKR",
    "LTL",
    "LVL",
    "LYD",
    "MAD",
    "MDL",
    "MGA",
    "MKD",
    "MMK",
    "MOP",
    "MUR",
    "MXN",
    "MYR",
    "MZN",
    "NAD",
    "NGN",
    "NIO",
    "NOK",
    "NPR",
    "NZD",
    "OMR",
    "PAB",
    "PEN",
    "PHP",
    "PKR",
    "PLN",
    "PYG",
    "QAR",
    "RON",
    "RSD",
    "RUB",
    "RWF",
    "SAR",
    "SDG",
    "SEK",
    "SGD",
    "SOS",
    "SYP",
    "THB",
    "TND",
    "TOP",
    "TRY",
    "TTD",
    "TWD",
    "TZS",
    "UAH",
    "UGX",
    "UYU",
    "UZS",
    "VEF",
    "VND",
    "XAF",
    "XOF",
    "YER",
    "ZAR",
    "ZMK",
    "ZWL"
  ];
}
