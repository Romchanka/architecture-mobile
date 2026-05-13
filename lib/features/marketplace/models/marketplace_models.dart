class Company {
  final int id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? phone;
  final String? email;

  Company({required this.id, required this.name, this.description, this.logoUrl, this.phone, this.email});

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: json['id'],
    name: json['name'] ?? '',
    description: json['description'],
    logoUrl: json['logoUrl'],
    phone: json['phone'],
    email: json['email'],
  );
}

class Complex {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? address;

  Complex({required this.id, required this.name, this.description, this.imageUrl, this.address});

  factory Complex.fromJson(Map<String, dynamic> json) => Complex(
    id: json['id'],
    name: json['name'] ?? '',
    description: json['description'],
    imageUrl: json['imageUrl'],
    address: json['address'],
  );
}

class Apartment {
  final int id;
  final String apartmentNumber;
  final int floor;
  final int rooms;
  final double areaTotal;
  final double? areaLiving;
  final double? areaKitchen;
  final double pricePerSqm;
  final double totalPrice;
  final String status;
  final String? layoutPlanUrl;
  final int? buildingId;

  Apartment({
    required this.id, required this.apartmentNumber, required this.floor,
    required this.rooms, required this.areaTotal, this.areaLiving, this.areaKitchen,
    required this.pricePerSqm, required this.totalPrice, required this.status,
    this.layoutPlanUrl, this.buildingId,
  });

  factory Apartment.fromJson(Map<String, dynamic> json) => Apartment(
    id: json['id'],
    apartmentNumber: json['apartmentNumber'] ?? '',
    floor: json['floor'] ?? 0,
    rooms: json['rooms'] ?? 0,
    areaTotal: (json['areaTotal'] ?? 0).toDouble(),
    areaLiving: json['areaLiving']?.toDouble(),
    areaKitchen: json['areaKitchen']?.toDouble(),
    pricePerSqm: (json['pricePerSqm'] ?? 0).toDouble(),
    totalPrice: (json['totalPrice'] ?? 0).toDouble(),
    status: json['status'] ?? 'AVAILABLE',
    layoutPlanUrl: json['layoutPlanUrl'],
    buildingId: json['buildingId'],
  );

  String get statusLabel {
    switch (status) {
      case 'AVAILABLE': return 'Свободна';
      case 'PREBOOKED': return 'Предбронь';
      case 'BOOKED': return 'Бронь';
      case 'INSTALLMENT': return 'Рассрочка';
      case 'SOLD': return 'Продано';
      default: return status;
    }
  }
}

class Booking {
  final int id;
  final String status;
  final String? bookingType;
  final String? apartmentNumber;
  final int? apartmentId;
  final String? userName;
  final String? consultantName;
  final String? notes;
  final bool expired;
  final bool active;
  final bool hasContract;
  final String createdAt;

  Booking({
    required this.id, required this.status, this.bookingType,
    this.apartmentNumber, this.apartmentId, this.userName,
    this.consultantName, this.notes,
    this.expired = false, this.active = false, this.hasContract = false,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'],
    status: json['status'] ?? '',
    bookingType: json['bookingType'],
    apartmentNumber: json['apartmentNumber']?.toString(),
    apartmentId: json['apartmentId'],
    userName: json['userName'],
    consultantName: json['consultantName'],
    notes: json['notes'],
    expired: json['expired'] ?? false,
    active: json['active'] ?? false,
    hasContract: json['hasContract'] ?? false,
    createdAt: json['createdAt'] ?? '',
  );

  String get statusLabel {
    switch (status) {
      case 'ACTIVE': return 'Активно';
      case 'CONVERTED': return 'Оформлено';
      case 'CANCELLED': return 'Отменено';
      case 'EXPIRED': return 'Истекло';
      default: return status;
    }
  }
}

class UserApartmentInfo {
  final int apartmentId;
  final String number;
  final double? totalArea;
  final int? floor;
  final int? rooms;
  final String? address;
  final double totalPrice;
  final double paidAmount;
  final double remainingAmount;

  UserApartmentInfo({
    required this.apartmentId, required this.number, this.totalArea,
    this.floor, this.rooms, this.address, required this.totalPrice,
    required this.paidAmount, required this.remainingAmount,
  });

  factory UserApartmentInfo.fromJson(Map<String, dynamic> json) =>
      UserApartmentInfo(
        apartmentId: json['apartmentId'],
        number: json['number'] ?? '',
        totalArea: json['totalArea']?.toDouble(),
        floor: json['floor'],
        rooms: json['rooms'],
        address: json['address'],
        totalPrice: (json['totalPrice'] ?? 0).toDouble(),
        paidAmount: (json['paidAmount'] ?? 0).toDouble(),
        remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      );
}

class ParkingSpace {
  final int id;
  final String number;
  final int? buildingId;
  final String? level;
  final double area;
  final double price;
  final String status;
  final bool isStacker;
  final String? notes;

  ParkingSpace({
    required this.id,
    required this.number,
    this.buildingId,
    this.level,
    required this.area,
    required this.price,
    required this.status,
    this.isStacker = false,
    this.notes,
  });

  factory ParkingSpace.fromJson(Map<String, dynamic> json) => ParkingSpace(
    id: json['id'],
    number: json['number'] ?? '',
    buildingId: json['buildingId'],
    level: json['level'],
    area: (json['area'] ?? 0).toDouble(),
    price: (json['price'] ?? 0).toDouble(),
    status: json['status'] ?? 'AVAILABLE',
    isStacker: json['isStacker'] ?? false,
    notes: json['notes'],
  );

  String get statusLabel {
    switch (status) {
      case 'AVAILABLE': return 'Свободна';
      case 'RESERVED': return 'Бронь';
      case 'SOLD': return 'Продано';
      default: return status;
    }
  }
}

class Story {
  final int id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? linkUrl;

  Story({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.linkUrl,
  });

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'],
    title: json['title'] ?? '',
    description: json['description'],
    imageUrl: json['imageUrl'] ?? '',
    linkUrl: json['linkUrl'],
  );
}

