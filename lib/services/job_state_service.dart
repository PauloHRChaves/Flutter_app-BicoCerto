class JobStateService {
  static final JobStateService _instance = JobStateService._internal();
  factory JobStateService() => _instance;
  JobStateService._internal();

  String? _currentJobId;

  void setCurrentJob(String jobId) {
    _currentJobId = jobId;
  }

  void clearCurrentJob() {
    if (_currentJobId != null) {
    }
    _currentJobId = null;
  }

  bool isViewingJob(String jobId) {
    final isViewing = _currentJobId == jobId;
    return isViewing;
  }

  String? getCurrentJob() {
    return _currentJobId;
  }

}