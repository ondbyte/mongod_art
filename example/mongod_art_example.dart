import 'dart:io';

import 'package:mongod_art/mongod_art.dart';

void main() async {
  final m = MongoDB();
  final data = MongoConnectionData(
    authenticationDataBase: "bapp-cms",
    userName: "bapp-dev",
    port: "27017",
    host: "cluster0.hmrzl.mongodb.net",
    passWord: "dG6Es3zoza102o04",
  );
  await m.init(data);
  print("response");
  await m.cooleDown;
  print("response");
  final response = await m.sample();
  print("response");
  print(response);
}
