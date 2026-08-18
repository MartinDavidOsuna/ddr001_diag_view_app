enum RemoteTestAction { none, begin, finish }

RemoteTestAction remoteTestAction({
  required bool measurementStarted,
  required bool controlFlowInRange,
  required double referenceLiters,
}) {
  if (!measurementStarted) {
    return controlFlowInRange ? RemoteTestAction.begin : RemoteTestAction.none;
  }
  return referenceLiters > 0 ? RemoteTestAction.finish : RemoteTestAction.none;
}
