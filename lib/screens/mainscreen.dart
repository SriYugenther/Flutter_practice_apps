import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shoppingapp/data/categories.dart';
import 'package:shoppingapp/data/dummy_items.dart';
import 'package:shoppingapp/models/grocery_item.dart';
import 'package:shoppingapp/screens/addscreen.dart';

import 'package:http/http.dart' as firebasehttp;

class MainScreen extends StatefulWidget {
  MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<GroceryItem> groceryitems = [];
  var isloading = true;

  String? _error;

  //init state is used to initialize this once the app restart
  @override
  void initState() {
    super.initState();
    loaditems();
    nsl();
  }

  void nsl() async {
    final nslurl =
        Uri.https("nsl.n-warehouse.com/retrieve-data/2023-07-11%2004:20:47");

    try {
      final nslresponse = await firebasehttp.get(nslurl);
      print(nslresponse.body);
    } catch (error) {
      print("something went wrong");
    }
  }

  //this function is used to get the data stored in the database
  void loaditems() async {
    final url = Uri.https(
        "flutter-prep-46c73-default-rtdb.firebaseio.com", 'shopping-list.json');

    try {
      final response = await firebasehttp.get(url);

      //print(response.body);

      //this is used to handle the error in the server side
      // if (response.statusCode >= 400) {
      //   setState(() {
      //     _error = "Something Went Wrong";
      //   });
      // }

      //if nodata is there in the database the type is not Map but null so we should handle it
      if (response.body == 'null') {
        setState(() {
          isloading = false;
        });
        return;
      }

      final Map<String, dynamic> Listdata = json.decode(response.body);

      final List<GroceryItem> loaditems = [];
      for (final abc in Listdata.entries) {
        //since we are sending only the category title we are doing this
        final category = categories.entries
            .firstWhere(
              (element) => element.value.title == abc.value["category"],
            )
            .value;

        loaditems.add(
          GroceryItem(
            id: abc.key,
            name: abc.value['name'],
            quantity: abc.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        groceryitems = loaditems;
        isloading = false;
      });
    } catch (error) {
      setState(() {
        _error = "Something Went Wrong";
      });
    }
  }

  void additem() async {
    //we will recieve the data from add screen using pop so here we will receive it and store it in a variable
    //this async and wait approch it used for that reason
    //after push in<> we are mentioning dart that this type of data is yeilded
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      groceryitems.add(newItem);
    });

    //since we are sending 2 request while adding a new item we can use the data in add screen and just display here
    ////that data will be sent to firebase using http request
    //loaditems();
  }

  void removeItem(GroceryItem removeitem) async {
    final groceryid = groceryitems.indexOf(removeitem);
    setState(() {
      groceryitems.remove(removeitem);
    });

    final url = Uri.https("flutter-prep-46c73-default-rtdb.firebaseio.com",
        'shopping-list/${removeitem.id}.json');

    final response = await firebasehttp.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        groceryitems.insert(groceryid, removeitem);
      });
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(removeitem.name + " is Deleted"),
        duration: const Duration(seconds: 3),
        // action: SnackBarAction(
        //     label: "Undo",
        //     onPressed: () {
        //       setState(() {
        //         groceryitems.insert(groceryid, removeitem);
        //       });
        //     }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text("Please Start Adding Groceries"));

    if (isloading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (groceryitems.isNotEmpty) {
      content = ListView.builder(
        //itemCount: groceryItems.length,
        itemCount: groceryitems.length,
        itemBuilder: (context, index) => Dismissible(
          //direction: DismissDirection.endToStart,
          key: ValueKey(groceryitems[index].id),
          background: Container(
            color: const Color.fromARGB(255, 3, 114, 7),
          ),
          onDismissed: (direction) {
            removeItem(groceryitems[index]);
            //print(index);
          },
          child: ListTile(
            //title: Text(groceryItems[index].name),
            title: Text(groceryitems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              //color: groceryItems[index].category.color,
              color: groceryitems[index].category.color,
            ),
            //onLongPress: () {},
            trailing: Text(
              //groceryItems[index].quantity.toString(),
              groceryitems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text("Your groceries"),
          actions: [IconButton(onPressed: additem, icon: Icon(Icons.add))],
        ),
        body: content);
  }
}
