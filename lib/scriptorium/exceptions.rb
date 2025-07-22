module Scriptorium::Exceptions

  def make_exception(sym, str, target_class = Object)
    return if target_class.constants.include?(sym)
    klass = sym   # :"#{sym}_Class"
    target_class.const_set(klass, StandardError.dup)
    define_method(sym) do |*args|
      args = [] unless args.first
      msg = str.dup
      args.each.with_index {|arg, i| msg.sub!("%#{i+1}", arg.to_s) }
      target_class.class_eval(klass.to_s).new(msg)
    end
  end

  make_exception :TestModeOnly, "Test mode only"
  make_exception :ViewDirAlreadyExists, "View directory already exists: %1"
  make_exception :RepoDirAlreadyExists, "Repository directory already exists: %1"
  make_exception :ViewDirDoesntExist, "View directory doesn't exist: %1"
  make_exception :MoreThanOneResult, "More than one result found for: %1"
  make_exception :CannotLookupView, "Cannot lookup view: %1"
  make_exception :ThemeDoesntExist, "Theme doesn't exist: %1" 
  make_exception :ThemeFileNotFound, "Theme file not found: %1"
  make_exception :LayoutHasUnknownTag, "Layout has unknown tag: %1"
  make_exception :LayoutHasDuplicateTags, "Layout has duplicate tags: %1"
  make_exception :AssetNotFound, "Asset not found: %1"
  make_exception :NoGemPath, "No gem path"

end
