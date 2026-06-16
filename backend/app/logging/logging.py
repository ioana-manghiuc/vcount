from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import sys
import sysconfig

_stdlib_logging_path = Path(sysconfig.get_paths()["stdlib"]) / "logging" / "__init__.py"
_spec = spec_from_file_location("logging_stdlib", _stdlib_logging_path)

if _spec is None or _spec.loader is None:  
	raise ImportError("Cannot load stdlib logging module")

_stdlib_logging = module_from_spec(_spec)

_spec.loader.exec_module(_stdlib_logging)  

sys.modules["logging"] = _stdlib_logging

globals().update(_stdlib_logging.__dict__)