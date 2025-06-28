module Scriptorium::Exceptions

  class TestModeOnly            < Exception; end
  class ViewDirAlreadyExists    < Exception; end
  class RepoDirAlreadyExists    < Exception; end
  class ViewDirDoesntExist      < Exception; end
  class MoreThanOneResult       < Exception; end
  class CannotLookupView        < Exception; end
  class ThemeDoesntExist        < Exception; end
  class ThemeFileNotFound       < Exception; end
  class LayoutHasUnknownTag     < Exception; end
  class LayoutHasDuplicateTags  < Exception; end
end
