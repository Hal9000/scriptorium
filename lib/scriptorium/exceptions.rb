module Scriptorium::Exceptions

  def make_exception(sym, str, target_class = Object)
    return if target_class.constants.include?(sym)
    klass = sym   # :"#{sym}_Class"
    target_class.const_set(klass, StandardError)
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
  make_exception :LayoutFileMissing, "Layout file missing: %1"
  make_exception :AssetNotFound, "Asset not found: %1"
  make_exception :NoGemPath, "No gem path"
  
  # Validation errors
  make_exception :NilValueError, "Value is nil: %1"
  make_exception :EmptyValueError, "Value is empty or whitespace-only: %1"
  make_exception :InvalidFormatError, "Invalid format '%1': %2"
  
  # Specific validation errors
  make_exception :CannotCreateViewNameNil, "Cannot create view: name is nil"
  make_exception :CannotCreateViewNameEmpty, "Cannot create view: name is empty or whitespace-only"
  make_exception :CannotCreateViewNameInvalid, "Cannot create view: invalid name '%1' (only alphanumeric, hyphen, and underscore allowed)"
  make_exception :CannotCreateViewTitleNil, "Cannot create view: title is nil"
  make_exception :CannotCreateViewTitleEmpty, "Cannot create view: title is empty or whitespace-only"
  
  make_exception :CannotLookupViewTargetNil, "Cannot lookup view: target is nil"
  make_exception :CannotLookupViewTargetEmpty, "Cannot lookup view: target is empty or whitespace-only"
  
  make_exception :CannotGetPostIdNil, "Cannot get post: id is nil"
  make_exception :CannotGetPostIdEmpty, "Cannot get post: id is empty or whitespace-only"
  make_exception :CannotGetPostIdInvalid, "Cannot get post: invalid id '%1' (must be numeric)"
  
  make_exception :CannotCreatePostRepoNil, "Cannot create post: repo is nil"
  make_exception :CannotCreatePostNumNil, "Cannot create post: num is nil"
  make_exception :CannotCreatePostNumEmpty, "Cannot create post: num is empty or whitespace-only"
  make_exception :CannotCreatePostNumInvalid, "Cannot create post: invalid num '%1' (must be numeric)"
  
  make_exception :CannotSetPubdateYmdNil, "Cannot set pubdate: ymd is nil"
  make_exception :CannotSetPubdateYmdEmpty, "Cannot set pubdate: ymd is empty or whitespace-only"
  make_exception :CannotSetPubdateInvalidFormat, "Cannot set pubdate: invalid date format '%1' (expected YYYY-MM-DD)"
  
  make_exception :CannotBuildWidgetsArgNil, "Cannot build widgets: argument is nil"
  make_exception :CannotBuildWidgetsArgEmpty, "Cannot build widgets: argument is empty or whitespace-only"
  make_exception :CannotBuildWidgetNameNil, "Cannot build widget: widget name is nil or empty"
  make_exception :CannotBuildWidgetNameInvalid, "Cannot build widget: invalid widget name '%1' (only alphanumeric and underscore allowed)"
  
  # File/IO errors
  make_exception :FileNotFoundError, "File not found: %1"
  make_exception :PermissionDeniedError, "Permission denied: %1"
  make_exception :DiskFullError, "Disk full: %1"
  make_exception :DirectoryNotFoundError, "Directory not found: %1"
  
  # Specific file/IO errors
  make_exception :CannotWriteFilePathNil, "Cannot write file: file path is nil"
  make_exception :CannotWriteFilePathEmpty, "Cannot write file: file path is empty or whitespace-only"
  make_exception :CannotWriteFilePermissionDenied, "Cannot write file %1: permission denied (%2)"
  make_exception :CannotWriteFileDiskFull, "Cannot write file %1: disk full (%2)"
  make_exception :CannotWriteFileDirectoryNotFound, "Cannot write file %1: directory not found (%2)"
  make_exception :CannotWriteFileError, "Cannot write file %1: %2"
  
  make_exception :CannotCreateDirectoryPathNil, "Cannot create directory: directory path is nil"
  make_exception :CannotCreateDirectoryPathEmpty, "Cannot create directory: directory path is empty or whitespace-only"
  make_exception :CannotCreateDirectoryPermissionDenied, "Cannot create directory %1: permission denied (%2)"
  make_exception :CannotCreateDirectoryParentNotFound, "Cannot create directory %1: parent directory not found (%2)"
  make_exception :CannotCreateDirectoryDiskFull, "Cannot create directory %1: disk full (%2)"
  make_exception :CannotCreateDirectoryError, "Cannot create directory %1: %2"
  
  make_exception :CannotReadFilePathNil, "Cannot read file: file path is nil"
  make_exception :CannotReadFilePathEmpty, "Cannot read file: file path is empty or whitespace-only"
  make_exception :CannotReadFileNotFound, "Cannot read file %1: file not found (%2)"
  make_exception :CannotReadFilePermissionDenied, "Cannot read file %1: permission denied (%2)"
  make_exception :CannotReadFileError, "Cannot read file %1: %2"
  
  make_exception :CannotEditFilePathNil, "Cannot edit file: file path is nil"
  make_exception :CannotEditFilePathEmpty, "Cannot edit file: file path is empty or whitespace-only"
  
  make_exception :CannotRequirePathNil, "Cannot require %1: path is nil"
  make_exception :CannotRequirePathEmpty, "Cannot require %1: path is empty or whitespace-only"
  make_exception :RequiredFileNotFound, "Required %1 not found: %2"
  make_exception :InvalidType, "Invalid type: %1 (must be :file or :dir)"
  
  # View errors
  make_exception :CannotCreateView, "Cannot create view: %1"
  make_exception :CannotBuildWidget, "Cannot build widget: %1"
  
  # Post errors
  make_exception :CannotCreatePost, "Cannot create post: %1"
  make_exception :CannotGetPost, "Cannot get post: %1"
  make_exception :CannotSetPubdate, "Cannot set pubdate: %1"
  
  # Banner SVG errors
  make_exception :CannotHandleBackground, "Cannot handle background: %1"
  make_exception :CannotHandleGradient, "Cannot handle gradient: %1"
  make_exception :CannotHandleImage, "Cannot handle image: %1"
  make_exception :CannotHandleAspect, "Cannot handle aspect: %1"
  make_exception :CannotHandleFont, "Cannot handle font: %1"
  make_exception :CannotHandleColor, "Cannot handle color: %1"
  make_exception :CannotHandleAlign, "Cannot handle align: %1"
  make_exception :CannotHandleXY, "Cannot handle xy: %1"
  
  # Specific Banner SVG errors
  make_exception :CannotHandleBackgroundNoArgs, "Cannot handle background: no arguments provided"
  make_exception :CannotHandleBackgroundFirstArgNil, "Cannot handle background: first argument is nil"
  make_exception :CannotHandleBackgroundFirstArgEmpty, "Cannot handle background: first argument is empty or whitespace-only"
  
  make_exception :CannotHandleLinearGradientNoArgs, "Cannot handle linear gradient: no arguments provided"
  make_exception :CannotHandleLinearGradientStartColorNil, "Cannot handle linear gradient: start color is nil or empty"
  make_exception :CannotHandleLinearGradientArgEmpty, "Cannot handle linear gradient: argument %1 is empty or whitespace-only"
  
  make_exception :CannotHandleRadialGradientNoArgs, "Cannot handle radial gradient: no arguments provided"
  make_exception :CannotHandleRadialGradientStartColorNil, "Cannot handle radial gradient: start color is nil or empty"
  make_exception :CannotHandleRadialGradientArgEmpty, "Cannot handle radial gradient: argument %1 is empty or whitespace-only"
  
  make_exception :CannotHandleImageBackgroundNoArgs, "Cannot handle image background: no arguments provided"
  make_exception :CannotHandleImageBackgroundFirstArgNil, "Cannot handle image background: first argument is nil"
  make_exception :CannotHandleImageBackgroundFirstArgEmpty, "Cannot handle image background: first argument is empty or whitespace-only"
  
  make_exception :CannotHandleAspectNoArgs, "Cannot handle aspect: no arguments provided"
  make_exception :CannotHandleAspectFirstArgNil, "Cannot handle aspect: first argument is nil"
  make_exception :CannotHandleAspectFirstArgEmpty, "Cannot handle aspect: first argument is empty or whitespace-only"
  make_exception :CannotHandleAspectInvalidValue, "Cannot handle aspect: invalid aspect value '%1' (must be numeric)"
  
  make_exception :CannotHandleFontArgsNil, "Cannot handle font: arguments are nil"
  make_exception :CannotHandleFontArgNil, "Cannot handle font: argument %1 is nil"
  make_exception :CannotHandleFontArgEmpty, "Cannot handle font: argument %1 is empty or whitespace-only"
  
  make_exception :CannotHandleTextColorNoArgs, "Cannot handle text color: no arguments provided"
  make_exception :CannotHandleTextColorFirstArgNil, "Cannot handle text color: first argument is nil"
  make_exception :CannotHandleTextColorFirstArgEmpty, "Cannot handle text color: first argument is empty or whitespace-only"
  
  make_exception :CannotHandleXYWhichNil, "Cannot handle xy: which is nil"
  make_exception :CannotHandleXYWhichEmpty, "Cannot handle xy: which is empty or whitespace-only"
  make_exception :CannotHandleXYInvalidWhich, "Cannot handle xy: invalid which '%1' (must be 'title' or 'subtitle')"
  
  make_exception :CannotHandleAlignNoArgs, "Cannot handle align: no arguments provided"
  make_exception :CannotHandleAlignDirectionNil, "Cannot handle align: direction is nil or empty"
  make_exception :CannotHandleAlignInvalidDirection, "Cannot handle align: invalid direction '%1' (must be 'left', 'center', or 'right')"
  make_exception :CannotHandleAlignArgEmpty, "Cannot handle align: argument %1 is empty or whitespace-only"
  
  make_exception :CannotHandleColorNoArgs, "Cannot handle color: no arguments provided"
  make_exception :CannotHandleColorFirstArgNil, "Cannot handle color: first argument is nil"
  make_exception :CannotHandleColorFirstArgEmpty, "Cannot handle color: first argument is empty or whitespace-only"
  
  # Command errors
  make_exception :CommandFailed, "Command failed: %1"
  make_exception :CannotExecuteCommand, "Cannot execute command: %1"
  
  # Specific command errors
  make_exception :CannotExecuteCommandNil, "Cannot execute command: command is nil"
  make_exception :CannotExecuteCommandEmpty, "Cannot execute command: command is empty or whitespace-only"
  make_exception :CommandFailedWithDesc, "Command failed%1: %2"
  
  # Section/Output errors
  make_exception :SectionOutputError, "Section output error: %1 (section: %2) - %3"
  make_exception :FailedToWriteFrontPage, "Failed to write front page: %1"

end
