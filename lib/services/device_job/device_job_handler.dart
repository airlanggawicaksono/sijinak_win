/// Payload handed to a [DeviceJobHandler]. The worker normalises the
/// transport-level [DeviceJobDTO] into this shape so handlers do not have to
/// know about HTTP / claim tokens.
class DeviceJobPayload {
  final String jobId;
  final String jobType;
  final Map<String, dynamic> data;

  const DeviceJobPayload({
    required this.jobId,
    required this.jobType,
    required this.data,
  });
}

/// Implement one handler per [jobType]. The worker dispatches by string.
///
/// Contract:
///   - Throw on failure. The worker reports the error and reschedules.
///   - Return normally on success — worker calls /complete.
///   - Handlers must be idempotent: a job may be re-executed after retry.
abstract class DeviceJobHandler {
  String get jobType;

  Future<void> execute(DeviceJobPayload payload);
}
