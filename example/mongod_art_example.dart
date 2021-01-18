import '../lib/mongod_art.dart';

void main() async {
  final m = MongoDB();
  /* final data = MongoConnectionData(
    authenticationDataBase: "bapp-cms",
    userName: "bapp-dev",
    port: "27017",
    host: "cluster0.hmrzl.mongodb.net",
    passWord: "dG6Es3zoza102o04",
  ); */
  await m.init(MongoConnectionData.defaultConnectionData());
  try {
    if (await m.sessionActive) {
      final response = await m.sample();
      print(response);
    } else {
      print("not cooled down");
    }
  } catch (e) {
    print(e);
  }
}
