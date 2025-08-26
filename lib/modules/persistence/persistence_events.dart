/// An event fired to command the PersistenceSystem to save all persistent entities.
class SaveDataEvent {}

/// An event fired by the PersistenceSystem after it has finished loading all
/// data from storage at startup. Other systems can listen for this to
/// initialize their state based on the loaded data.
class DataLoadedEvent {}
