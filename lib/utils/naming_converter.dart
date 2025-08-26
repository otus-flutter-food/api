/// Utility functions for converting between camelCase and snake_case
class NamingConverter {
  
  /// Convert camelCase string to snake_case
  /// Example: firstName -> first_name, avatarUrl -> avatar_url
  static String camelToSnake(String camelCase) {
    return camelCase.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}',
    );
  }
  
  /// Convert snake_case string to camelCase
  /// Example: first_name -> firstName, avatar_url -> avatarUrl
  static String snakeToCamel(String snakeCase) {
    if (!snakeCase.contains('_')) return snakeCase;
    
    final parts = snakeCase.split('_');
    return parts.first + 
           parts.skip(1).map((part) => 
             part.isNotEmpty ? '${part[0].toUpperCase()}${part.substring(1)}' : ''
           ).join();
  }
  
  /// Recursively convert Map keys from camelCase to snake_case
  static Map<String, dynamic> convertMapKeysToSnake(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    
    input.forEach((key, value) {
      final snakeKey = camelToSnake(key);
      
      if (value is Map<String, dynamic>) {
        result[snakeKey] = convertMapKeysToSnake(value);
      } else if (value is List) {
        result[snakeKey] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return convertMapKeysToSnake(item);
          }
          return item;
        }).toList();
      } else {
        result[snakeKey] = value;
      }
    });
    
    return result;
  }
  
  /// Recursively convert Map keys from snake_case to camelCase
  static Map<String, dynamic> convertMapKeysToCamel(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    
    input.forEach((key, value) {
      final camelKey = snakeToCamel(key);
      
      if (value is Map<String, dynamic>) {
        result[camelKey] = convertMapKeysToCamel(value);
      } else if (value is List) {
        result[camelKey] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return convertMapKeysToCamel(item);
          }
          return item;
        }).toList();
      } else {
        result[camelKey] = value;
      }
    });
    
    return result;
  }
  
  /// Convert response data (outgoing to client)
  /// This ensures API responses use camelCase for Flutter clients
  static dynamic convertResponseToCamelCase(dynamic data) {
    if (data is Map<String, dynamic>) {
      return convertMapKeysToCamel(data);
    } else if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return convertMapKeysToCamel(item);
        }
        return item;
      }).toList();
    }
    return data;
  }
  
  /// Convert request data (incoming from client)
  /// This allows Flutter clients to send camelCase but converts to snake_case for DB
  static dynamic convertRequestToSnakeCase(dynamic data) {
    if (data is Map<String, dynamic>) {
      return convertMapKeysToSnake(data);
    } else if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return convertMapKeysToSnake(item);
        }
        return item;
      }).toList();
    }
    return data;
  }
}