class DeliveryAssignment {
  const DeliveryAssignment({required this.id, required this.packageId, required this.courierId, required this.status, required this.assignedAt});
  final String id, packageId, courierId, status;
  final DateTime assignedAt;
  factory DeliveryAssignment.fromMap(Map<String,dynamic> m)=>DeliveryAssignment(
    id:m['id'] as String, packageId:m['package_id'] as String, courierId:m['courier_id'] as String,
    status:m['status'].toString(), assignedAt:DateTime.parse(m['assigned_at'] as String));
}