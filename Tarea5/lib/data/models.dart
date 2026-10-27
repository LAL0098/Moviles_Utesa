class User {
  final Map<String, dynamic> json;
  User(this.json);
  int get id => json['id'] as int;
  String get name => json['name'] as String;
  String get email => json['email'] as String;
  String get company => json['company']['name'] as String;
  String get username => json['username'] as String;
  String get phone => json['phone'] as String;
  String get website => json['website'] as String;
  String get address {
    final a = json['address'];
    return '${a['street']}, ${a['suite']}, ${a['city']} (${a['zipcode']})';
  }
}

class Post {
  final int id;
  final String title, body;
  Post(this.id, this.title, this.body);
  factory Post.fromJson(Map<String, dynamic> j) =>
      Post(j['id'] as int, j['title'] as String, j['body'] as String);
}
