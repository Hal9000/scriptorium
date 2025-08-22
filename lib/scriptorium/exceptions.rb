module Scriptorium::Exceptions

  def make_exception(sym, str, target_class = Object)
    return if target_class.constants.include?(sym)
    klass = sym 
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
  make_exception :ViewNameNil, "Cannot create view: name is nil"
  make_exception :ViewNameEmpty, "Cannot create view: name is empty or whitespace-only"
  make_exception :ViewNameInvalid, "Cannot create view: invalid name '%1' (only alphanumeric, hyphen, and underscore allowed)"
  make_exception :ViewTitleNil, "Cannot create view: title is nil"
  make_exception :ViewTitleEmpty, "Cannot create view: title is empty or whitespace-only"
  make_exception :ViewTargetNil, "Cannot lookup view: target is nil"
  make_exception :ViewTargetEmpty, "Cannot lookup view: target is empty or whitespace-only"
  make_exception :ViewTargetInvalid, "Cannot lookup view: invalid target '%1' (must be 'view' or 'post')"
  
  make_exception :PostIdNil, "Cannot get post: id is nil"
  make_exception :PostIdEmpty, "Cannot get post: id is empty or whitespace-only"
  make_exception :PostIdInvalid, "Cannot get post: invalid id '%1' (must be numeric)"
  
  make_exception :PostRepoNil, "Cannot create post: repo is nil"
  make_exception :PostNumNil, "Cannot create post: num is nil"
  make_exception :PostNumEmpty, "Cannot create post: num is empty or whitespace-only"
  make_exception :PostNumInvalid, "Cannot create post: invalid num '%1' (must be numeric)"
  
  make_exception :PubdateYmdNil, "Cannot set pubdate: ymd is nil"
  make_exception :PubdateYmdEmpty, "Cannot set pubdate: ymd is empty or whitespace-only"
  make_exception :PubdateInvalidFormat, "Cannot set pubdate: invalid date format '%1' (expected YYYY-MM-DD)"
  
  make_exception :WidgetsArgNil, "Cannot build widgets: argument is nil"
  make_exception :WidgetsArgEmpty, "Cannot build widgets: argument is empty or whitespace-only"
  make_exception :WidgetNameNil, "Cannot build widget: widget name is nil or empty"
  make_exception :WidgetNameInvalid, "Cannot build widget: invalid widget name '%1' (only alphanumeric and underscore allowed)"
  
  # File/IO errors
  make_exception :FileNotFoundError, "File not found: %1"
  make_exception :PermissionDeniedError, "Permission denied: %1"
  make_exception :DiskFullError, "Disk full: %1"
  make_exception :DirectoryNotFoundError, "Directory not found: %1"
  
  # Specific file/IO errors
  make_exception :FilePathNil, "Cannot write file: file path is nil"
  make_exception :FilePathEmpty, "Cannot write file: file path is empty or whitespace-only"
  make_exception :FilePermissionDenied, "Cannot write file %1: permission denied (%2)"
  make_exception :FileDiskFull, "Cannot write file %1: disk full (%2)"
  make_exception :FileDirectoryNotFound, "Cannot write file %1: directory not found (%2)"
  make_exception :CannotWriteFileError, "Cannot write file %1: %2"
  
  make_exception :DirectoryPathNil, "Cannot create directory: directory path is nil"
  make_exception :DirectoryPathEmpty, "Cannot create directory: directory path is empty or whitespace-only"
  make_exception :DirectoryPermissionDenied, "Cannot create directory %1: permission denied (%2)"
  make_exception :DirectoryParentNotFound, "Cannot create directory %1: parent directory not found (%2)"
  make_exception :DirectoryDiskFull, "Cannot create directory %1: disk full (%2)"
  make_exception :DirectoryError, "Cannot create directory %1: %2"
  
  make_exception :ReadFilePathNil, "Cannot read file: file path is nil"
  make_exception :ReadFilePathEmpty, "Cannot read file: file path is empty or whitespace-only"
  make_exception :ReadFileNotFound, "Cannot read file %1: file not found (%2)"
  make_exception :ReadFilePermissionDenied, "Cannot read file %1: permission denied (%2)"
  make_exception :ReadFileError, "Cannot read file %1: %2"
  
  make_exception :EditFilePathNil, "Cannot edit file: file path is nil"
  make_exception :EditFilePathEmpty, "Cannot edit file: file path is empty or whitespace-only"
  
  make_exception :RequirePathNil, "Cannot require %1: path is nil"
  make_exception :RequirePathEmpty, "Cannot require %1: path is empty or whitespace-only"
  make_exception :RequiredFileNotFound, "Required %1 not found: %2"
  make_exception :InvalidType, "Invalid type: %1 (must be :file or :dir)"
  
  # View errors
  make_exception :CannotCreateView, "Cannot create view: %1"
  make_exception :CannotBuildWidget, "Cannot build widget: %1"
  
  # Post errors
  make_exception :CannotCreatePost, "Cannot create post: %1"
  make_exception :CannotGetPost, "Cannot get post: %1"
  make_exception :PostAlreadyPublished, "Post %1 is already published"
  make_exception :CannotSetPubdate, "Cannot set pubdate: %1"
  
  # Banner SVG errors
  make_exception :InvalidBackground, "Cannot handle background: %1"
  make_exception :InvalidGradient, "Cannot handle gradient: %1"
  make_exception :InvalidImage, "Cannot handle image: %1"
  make_exception :InvalidAspect, "Cannot handle aspect: %1"
  make_exception :InvalidFont, "Cannot handle font: %1"
  make_exception :InvalidColor, "Cannot handle color: %1"
  make_exception :InvalidAlign, "Cannot handle align: %1"
  make_exception :InvalidXY, "Cannot handle xy: %1"
  
  # Specific Banner SVG errors
  make_exception :BackgroundNoArgs, "Cannot handle background: no arguments provided"
  make_exception :BackgroundFirstArgNil, "Cannot handle background: first argument is nil"
  make_exception :BackgroundFirstArgEmpty, "Cannot handle background: first argument is empty or whitespace-only"
  
  make_exception :LinearGradientNoArgs, "Cannot handle linear gradient: no arguments provided"
  make_exception :LinearGradientStartColorNil, "Cannot handle linear gradient: start color is nil or empty"
  make_exception :LinearGradientArgEmpty, "Cannot handle linear gradient: argument %1 is empty or whitespace-only"
  
  make_exception :RadialGradientNoArgs, "Cannot handle radial gradient: no arguments provided"
  make_exception :RadialGradientStartColorNil, "Cannot handle radial gradient: start color is nil or empty"
  make_exception :RadialGradientArgEmpty, "Cannot handle radial gradient: argument %1 is empty or whitespace-only"
  
  make_exception :ImageBackgroundNoArgs, "Cannot handle image background: no arguments provided"
  make_exception :ImageBackgroundFirstArgNil, "Cannot handle image background: first argument is nil"
  make_exception :ImageBackgroundFirstArgEmpty, "Cannot handle image background: first argument is empty or whitespace-only"
  
  make_exception :AspectNoArgs, "Cannot handle aspect: no arguments provided"
  make_exception :AspectFirstArgNil, "Cannot handle aspect: first argument is nil"
  make_exception :AspectFirstArgEmpty, "Cannot handle aspect: first argument is empty or whitespace-only"
  make_exception :AspectInvalidValue, "Cannot handle aspect: invalid aspect value '%1' (must be numeric)"
  
  make_exception :FontArgsNil, "Cannot handle font: arguments are nil"
  make_exception :FontArgNil, "Cannot handle font: argument %1 is nil"
  make_exception :FontArgEmpty, "Cannot handle font: argument %1 is empty or whitespace-only"
  
  make_exception :TextColorNoArgs, "Cannot handle text color: no arguments provided"
  make_exception :TextColorFirstArgNil, "Cannot handle text color: first argument is nil"
  make_exception :TextColorFirstArgEmpty, "Cannot handle text color: first argument is empty or whitespace-only"
  
  make_exception :XYWhichNil, "Cannot handle xy: which is nil"
  make_exception :XYWhichEmpty, "Cannot handle xy: which is empty or whitespace-only"
  make_exception :XYInvalidWhich, "Cannot handle xy: invalid which '%1' (must be 'title' or 'subtitle')"
  
  make_exception :AlignNoArgs, "Cannot handle align: no arguments provided"
  make_exception :AlignDirectionNil, "Cannot handle align: direction is nil or empty"
  make_exception :AlignInvalidDirection, "Cannot handle align: invalid direction '%1' (must be 'left', 'center', or 'right')"
  make_exception :AlignArgEmpty, "Cannot handle align: argument %1 is empty or whitespace-only"
  
  make_exception :ColorNoArgs, "Cannot handle color: no arguments provided"
  make_exception :ColorFirstArgNil, "Cannot handle color: first argument is nil"
  make_exception :ColorFirstArgEmpty, "Cannot handle color: first argument is empty or whitespace-only"
    
  # Command errors
  make_exception :CommandFailed, "Command failed: %1"
  make_exception :CannotExecuteCommand, "Cannot execute command: %1"
  
  # Specific command errors
  make_exception :CommandNil, "Cannot execute command: command is nil"
  make_exception :CommandEmpty, "Cannot execute command: command is empty or whitespace-only"
  make_exception :CommandFailedWithDesc, "Command failed%1: %2"
  
  # Section/Output errors
  make_exception :SectionOutputError, "Section output error: %1 (section: %2) - %3"
  make_exception :WriteFrontPageError, "Failed to write front page: %1"

  # Theme management errors
  make_exception :ThemeNotFound, "Theme not found: %1"
  make_exception :ThemeAlreadyExists, "Theme already exists: %1"
  make_exception :ThemeNameInvalid, "Theme name must contain only letters, numbers, hyphens, and underscores: %1"

  # Draft management errors
  make_exception :DraftPathNil, "Draft path cannot be nil"
  make_exception :DraftPathEmpty, "Draft path cannot be empty"
  make_exception :DraftFileInvalid, "Not a valid draft file: %1"
  make_exception :DraftFileNotFound, "Draft file not found: %1"

  # Search/Query errors
  make_exception :UnknownSearchField, "Unknown search field: %1"

  # Deployment errors
  make_exception :DeploymentNotReady, "View '%1' is not ready for deployment. Check status and configuration."
  make_exception :DeploymentFieldsMissing, "Missing required deployment fields: %1"
  make_exception :DeploymentFailed, "Deployment failed with exit code %1"

end
