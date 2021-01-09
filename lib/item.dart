class Item {
  Item(this.title, this.subtitle, this.items, this.points, this.maxSelections,
      this.allowMultiple, this.exclusive);

  String title;
  String subtitle;
  List<Item> items;
  int points;
  int maxSelections;
  bool allowMultiple;
  bool exclusive;

  Item.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        subtitle = json['subtitle'],
        items = json['items'] != null
            ? List<Item>.from(json['items'].map((i) => Item.fromJson(i)))
            : <Item>[],
        points = json['points'],
        maxSelections = json['maxSelections'],
        allowMultiple = json['allowMultiple'],
        exclusive = json['exclusive'];

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'items': items,
        'points': points,
        'maxSelections': maxSelections,
        'allowMultiple': allowMultiple,
        'exclusive': exclusive
      };
}
