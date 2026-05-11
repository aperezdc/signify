project('signify', 'c',
  version: '33',
  license: 'BSD-2-Clause',
  meson_version: '>=1.4',
)

cc = meson.get_compiler('c')

compat_h_file = files('compat.h')[0]
cc.has_multi_arguments('-include', compat_h_file.full_path(), required: true)
signify_cflags = ['-include', compat_h_file.full_path()]

sed_exe = find_program(['sed', 'gsed'], native: true, required: true)

signify_extra_sources = [
  custom_target(
    output: 'sha256hl.c',
    input: 'helper.c',
    capture: true,
    command: [sed_exe,
      '-e', 's/hashinc/sha2.h/g',
      '-e', 's/HASH_CTX/SHA2_CTX/g',
      '-e', 's/HASH/SHA256/g',
      '@INPUT@',
    ],
  ),
  custom_target(
    output: 'sha512hl.c',
    input: 'helper.c',
    capture: true,
    command: [sed_exe,
      '-e', 's/hashinc/sha2.h/g',
      '-e', 's/HASH_CTX/SHA2_CTX/g',
      '-e', 's/HASH/SHA512/g',
      '@INPUT@',
    ],
  ),
  custom_target(
    output: 'sha512_256hl.c',
    input: 'helper.c',
    capture: true,
    command: [sed_exe,
      '-e', 's/hashinc/sha2.h/g',
      '-e', 's/HASH_CTX/SHA2_CTX/g',
      '-e', 's/HASH/SHA512_256/g',
      '@INPUT@',
    ],
  ),
]

bundled_libbsd = get_option('bundled_libbsd')
libbsd_dep = disabler()

if not bundled_libbsd.enabled()
  libbsd_dep = dependency('libbsd-overlay', version: '>=0.11', required: bundled_libbsd.disabled())
endif

if not libbsd_dep.found() and not bundled_libbsd.disabled()
  libbsdbundled_feature_flags = []
  foreach item : ['__PROGNAME', 'GETEXECNAME', 'PROGRAM_INVOCATION_SHORT_NAME']
    if cc.links(files('conf/HAVE_' + item + '.c'), args: signify_cflags)
      libbsdbundled_feature_flags += ['-DHAVE_' + item]
    endif
  endforeach
  libbsdbundled_flags = ['-DLIBBSD_OVERLAY']
  libbsdbundled_inc = include_directories('libbsd/bsd', is_system: true)
  libbsdbundled_lib = static_library('libbsdbundled',
    'libbsd/arc4random.c',
    'libbsd/freezero.c',
    'libbsd/progname.c',
    'libbsd/readpassphrase.c',
    'libbsd/strlcpy.c',
    include_directories: libbsdbundled_inc,
    c_args: signify_cflags + libbsdbundled_feature_flags + libbsdbundled_flags,
  )
  libbsd_dep = declare_dependency(
    include_directories: libbsdbundled_inc,
    compile_args: libbsdbundled_flags,
    link_with: libbsdbundled_lib,
  )
endif

signify_dependencies = [libbsd_dep]

if not cc.has_function('explicit_bzero', prefix: '#include <string.h>')
  signify_extra_sources += ['explicit_bzero.c']
  signify_cflags += ['-DBUNDLED_BZERO']
endif

if get_option('waive').enabled()
  libwaive_lib = static_library('libwaive',
    'libwaive/waive.c',
    dependencies: dependency('libseccomp', required: true),
  )
  libwaive_dep = declare_dependency(
    link_with: libwaive_lib,
    include_directories: include_directories('libwaive'),
  )
  signify_dependencies += [libwaive_dep]
  signify_extra_sources += ['pledge_waive.c']
else
  signify_extra_sources += ['pledge_noop.c']
endif

libsignifynowarn_lib = static_library('libsignify_nowarn',
  'signify.c',
  'bcrypt_pbkdf.c',
  'zsig.c',
  c_args: signify_cflags + cc.get_supported_arguments('-Wno-pointer-sign'),
  dependencies: signify_dependencies,
  install: false,
)

signify_exe = executable('signify',
  'base64.c',
  'blowfish.c',
  'crypto_api.c',
  'fe25519.c',
  'mod_ed25519.c',
  'mod_ge25519.c',
  'ohash.c',
  'sc25519.c',
  'sha2.c',
  'timingsafe_bcmp.c',
  signify_extra_sources,
  c_args: signify_cflags,
  dependencies: signify_dependencies,
  link_with: libsignifynowarn_lib,
  install: true,
  build_by_default: true,
)

install_man('signify.1')

test('regress',
  files('regress/run'),
  depends: signify_exe,
  is_parallel: false,
  env: {
    'SIGNIFY_EXE_PATH': signify_exe.full_path(),
  },
)
