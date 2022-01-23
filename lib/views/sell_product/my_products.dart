import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syboard/models/order.dart';
import 'package:syboard/models/user_obj.dart';
import 'package:syboard/services/auth.dart';
import 'package:syboard/services/service.dart';
import 'package:syboard/utils/dimension.dart';
import 'package:syboard/models/product.dart';
import 'package:syboard/ui/edit_product_preview.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syboard/utils/styles.dart';
import 'package:syboard/views/sell_history.dart';
import 'package:syboard/views/sold_order_card.dart';

class MyProducts extends StatefulWidget {
  const MyProducts({Key? key, this.analytics, this.observer}) : super(key: key);
  final FirebaseAnalytics? analytics;
  final FirebaseAnalyticsObserver? observer;

  @override
  State<MyProducts> createState() => _MyProductsState();
}

class _MyProductsState extends State<MyProducts> {
  TextEditingController searchTextController = TextEditingController();

  List<Product> productsOnSale = [];

  Future<List<Product>> getAProducts() async {
    var sellerRef =
    Service.userCollection.doc(Provider.of<UserObj?>(context)!.uid);
    var productsDocs =
        (await Service.productCollection.where("seller", isEqualTo: sellerRef).get())
            .docs;
    List<Product> productsList = <Product>[];
    for (var i = 0; i < productsDocs.length; i++) {
      var currentProductDoc = productsDocs[i];
      DocumentReference sellerRef = currentProductDoc.get("seller");
      String sellerName = (await sellerRef.get()).get("sellerName");
      var currentProduct = Product(
          pid: currentProductDoc.id,
          imgURL: currentProductDoc["imgURL"],
          productName: currentProductDoc.get("productName"),
          rating: currentProductDoc.get("rating"),
          price: currentProductDoc.get("price"),
          seller: sellerName,
          description: currentProductDoc.get("description"),
          category: currentProductDoc["category"],
          tag: currentProductDoc["tag"],
          onSale: currentProductDoc["onSale"],
          stocks: currentProductDoc["stocks"],
          oldPrice: currentProductDoc["oldPrice"] ?? 0);

      productsList.add(currentProduct);
    }
    filterProductsOnSale(productsList);

    return productsList;
  }


  Future<List<Order>> getOrders() async {
    print("SOLD PRODUCT: ---");

    List<Order> orders = [];
    final user = Provider.of<UserObj?>(context);
    var sellerRef = Service.userCollection.doc(user?.uid);
    var o = await Service.ordersCollection
        .where("seller", isEqualTo: sellerRef)
        .get();
    for (var element in o.docs) {
      DocumentReference currentProduct = element.get("product");
      String currentProductName = (await currentProduct.get()).get("productName");
      num currentProductPrice = (await currentProduct.get()).get("price");
      String currentProductPicture =
      (await currentProduct.get()).get("imgURL");
      String currentPid = currentProduct.id;
      orders.add(Order(
        //buyer: currentBuyerName,
        //oid: element.id,
          url: currentProductPicture,
          productName: currentProductName,
          pid: currentPid,
          price: currentProductPrice,
          purchaseDate: element.get("purchaseDate"),
          amount: element.get("amount"),
          orderID: element.id,
          comment: element.get("comment"),
          isCommented: element.get("isCommented"),
          isRated: element.get("isRated"),
          rating: element.get("rating"),
          commentApproved: element.get("commentApproved")
      ));
    }
    return orders;
  }

  filterProductsOnSale(List<Product> pAll){

    List<Product> catProducts = [];
     pAll.forEach((item) => {
        if(item.onSale == true){
          catProducts.add(item)
        },


     });
    //  setState(() {
    //       productsOnSale = catProducts;
    // });


  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    UserObj? currentUser = Provider.of<UserObj?>(context);

    return FutureBuilder(
        future: Future.wait([getAProducts(),getOrders()]),
        builder: (context, AsyncSnapshot<List<List<dynamic>>> snapshot) {
          if (!snapshot.hasData) {
            return const Text("Loading..");
          } else if (((snapshot.data)![0]).isEmpty) {
            return const Center(
                child:
                    Text("You are not selling any products. Try adding some!"));
          }
          List<Product>  allProducts = (snapshot.data)?[0] as List<Product>;
          List<Order>  soldProducts = (snapshot.data)?[1] as List<Order>;
          double total = 0.0;
          double _rating = 0.0;
          soldProducts.forEach((order){
            total += order.rating;
          });
          _rating = total / soldProducts.length;

          return Scaffold(
            body:  Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("${currentUser?.name ?? currentUser!.email!}'s Current Rating" ,
                  style: kTextTitleMedium,

                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text( _rating.toString(),
                  style: kTextTitleMedium,

                    ),
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    ],
                  )
                  ],
                ),

                // SizedBox(height: 30,),
                // Column(
                //   children: [
                //     Text('Products Sold' ,
                //       style: kTextTitle,

                //     ),
                //     SingleChildScrollView(
                //       scrollDirection: Axis.horizontal,
                //       child: Padding(
                //         padding: Dimen.regularPadding,
                //         child: Row(
                //           children: List.generate(
                //               soldProducts.length,
                //                   (index) => Row(children: [

                //                     SoldOrderCard(order: soldProducts[index]),
                //                 const SizedBox(width: 8)
                //               ])),
                //         ),
                //       ),
                //     )   ,
                //   ],
                // ),

                // SizedBox(height: 30,),
                // Column(
                //   children: [
                //      Text('Products On Sale' ,
                //   style: kTextTitle,

                //     ),
                //     SingleChildScrollView(
                //     scrollDirection: Axis.horizontal,
                //     child: Padding(
                //       padding: Dimen.regularPadding,
                //       child: Row(
                //         children: List.generate(
                //             productsOnSale.length,
                //             (index) => Row(children: [
                //                   editProductPreview(productsOnSale[index], context,
                //                       () {
                //                     setState(() {});
                //                   }),
                //                   const SizedBox(width: 8)
                //                 ])),
                //       ),
                //     ),
                //    )   ,
                //   ],
                // ),
                SizedBox(height: 30,),

                 Column(
                  children: [
                     Text("All Products",
                  style: kTextTitle,

                    ),
                    // SellHistory(uid:  Service.userCollection.doc(Provider.of<UserObj?>(context)!.uid).toString()),
                    SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: Dimen.regularPadding,
                      child: Row(
                        children: List.generate(
                            allProducts.length,
                            (index) => Row(children: [
                                  editProductPreview(allProducts[index], context,
                                      () {
                                  }),
                                  const SizedBox(width: 8)
                                ])),
                      ),
                    ),
                   )   ,
                  ],
                ),

              ],
            ),
            )
          ,
              )
            );
        });
  }
}
