import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shoppingapp/data/categories.dart';
import 'package:shoppingapp/models/category.dart';
import 'package:shoppingapp/models/grocery_item.dart';

import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  const NewItem({super.key});
  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final formkey = GlobalKey<FormState>();
  var enteredname = '';
  var enteredquantity = 1;
  var selectedcategory = categories[Categories.vegetables]!;

  //this varible is used to prevent user to click add button more than once when the http request takes more time
  var issaving = false;

  void saveitem() async {
    if (formkey.currentState!.validate()) {
      formkey.currentState!.save();

      setState(() {
        issaving = true;
      });

      //these set of code is used to post the data to firebase

      //in Uri.https(firebase line,key type)
      final url = Uri.https("flutter-prep-46c73-default-rtdb.firebaseio.com",
          'shopping-list.json');

      var response = await http.post(
        url,
        headers: {
          //string:json
          "content-type": "application/json",
        },
        body: json.encode(
          {
            "name": enteredname,
            "quantity": enteredquantity,
            "category": selectedcategory.title
          },
        ),
      );

      final Map<String, dynamic> id = json.decode(response.body);

      //since we are using async the flutter will show not to use context so we are checking whether the wait is over or not
      if (!context.mounted) {
        return;
      }

      //using pop to send data to previous screen
      Navigator.of(context).pop(GroceryItem(
          id: id["name"],
          name: enteredname,
          quantity: enteredquantity,
          category: selectedcategory));
    }
    // print(enteredname);
    // print(enteredquantity);
    // print(selectedcategory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),

        //this form can be used for getting user input,validation error
        child: Form(
          //key is used for validation
          key: formkey,
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextFormField(
                maxLength: 30,
                decoration: const InputDecoration(label: Text("Name")),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 30) {
                    return "Please enter valid Data";
                  }
                  // if this validator returns null then there is no error
                  return null;
                },
                onSaved: (value) {
                  enteredname = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                      child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(label: Text("Quantity")),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null ||
                          int.tryParse(value)! <= 0) {
                        return "Enter valid number";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      enteredquantity = int.parse(value!);
                    },
                  )),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                        value: selectedcategory,
                        items: [
                          //.enteries used to convert map to list(iterable)
                          for (final abc in categories.entries)
                            DropdownMenuItem(
                                value: abc.value,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      color: abc.value.color,
                                    ),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                    Text(abc.value.title)
                                  ],
                                ))
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedcategory = value!;
                          });
                        }),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(
                      //in flutter the button can ve disable by passing null
                      //so it issaving is true the buuton will not work
                      //if issaving is false the button is constant

                      onPressed: issaving
                          ? null
                          : () {
                              formkey.currentState!.reset();
                            },
                      child: const Text("Reset")),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: issaving ? null : saveitem,
                    child: issaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text("Add Item"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
