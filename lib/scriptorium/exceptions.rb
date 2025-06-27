module Scriptorium::Exceptions

  class TestModeOnly            < Exception; end
  class ViewDirAlreadyExists    < Exception; end
  class RepoDirAlreadyExists    < Exception; end
  class ViewDirDoesntExist      < Exception; end
  class MoreThanOneResult       < Exception; end
  class CannotLookupView        < Exception; end
end
