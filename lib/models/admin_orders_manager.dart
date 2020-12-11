import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lojavirtual/models/user.dart';

import 'order.dart';

class AdminOrdersManager extends ChangeNotifier {


  final List<Order> _orders = [];
  StreamSubscription _subscription;

  User userFilter;
  List<Status> statusFilter = [Status.preparing];

  final Firestore firestore = Firestore.instance;

  // ignore: avoid_positional_boolean_parameters
  void updateAdmin(bool adminEnabled) {

    _orders.clear();

    _subscription?.cancel();
    if (adminEnabled) {
      _listenToOrders();
    }
  }

  List<Order> get filteredOrders{
    List<Order> output = _orders.reversed.toList();

    if(userFilter != null){
      output = output.where((o) => o.userId == userFilter.id).toList();
    }

    return output.where((element) => statusFilter.contains(element.status)).toList();

  }

  void _listenToOrders() {
    _subscription = firestore.collection('orders').snapshots().listen((event) {
      for(final change in event.documentChanges){
        switch(change.type){
          case DocumentChangeType.added:
            _orders.add(
                Order.fromDocument(change.document)
            );
            break;
          case DocumentChangeType.modified:
            final modOrder = _orders.firstWhere(
                    (o) => o.orderId == change.document.documentID);
            modOrder.updateFromDocument(change.document);
            break;
          case DocumentChangeType.removed:
            debugPrint('Deu problema sério!!!');
            break;
        }
      }

      notifyListeners();
    });
  }

  void setUserFilter(User user){
    userFilter = user;
    notifyListeners();
  }

  void setStatusFilter({Status status, bool enabled}){
    if(enabled) {
      statusFilter.add(status);
    } else {
      statusFilter.remove(status);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }
}
