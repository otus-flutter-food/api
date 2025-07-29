void main() {
  const quotedColumns = ['caloriesForUnit', 'dateTime', 'measureUnit_id'];
  
  String getColumnName(String key) {
    return quotedColumns.contains(key) ? '"$key"' : key;
  }
  
  final columns = ['id', 'text', 'dateTime', 'photo', 'user_id', 'recipe_id'];
  final returningColumns = columns.map((col) => getColumnName(col)).join(', ');
  
  print('Returning columns: $returningColumns');
}
