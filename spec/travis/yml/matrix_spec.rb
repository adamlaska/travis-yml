describe Travis::Yml, 'matrix' do
  def self.expands_to(rows)
    it { should eq rows }
  end

  let(:data)   { {} }
  let(:config) { described_class.apply(parse(yaml), opts).serialize }
  let(:matrix) { described_class.matrix(config: config, data: data) }

  subject { matrix.rows }

  describe 'no matrix' do
    yaml ''
    expands_to [{}]
  end

  describe 'matrix (1)' do
    yaml %(
      rvm: 2.2
      gemfile: str
    )

    expands_to [
      { rvm: '2.2', gemfile: 'str' }
    ]
  end

  describe 'matrix (1 from include, redundant expand key at root)' do
    yaml %(
      os: linux
      jobs:
        include:
          - os: osx
            env: FOO=foo
    )

    expands_to [
      { os: 'osx', env: [FOO: 'foo'] }
    ]
  end

  describe 'matrix (1 from include, multi-value expand key at root)' do
    yaml %(
      os:
      - linux
      - osx
      jobs:
        include:
          - env: FOO=foo
    )

    expands_to [
      { os: 'linux' },
      { os: 'osx' },
      { os: 'linux', env: [FOO: 'foo'] }
    ]
  end

  describe 'matrix (1 with non-expand key at root)' do
    yaml %(
    language: rust
    jobs:
      include:
        env: FOO=foo
    )

    expands_to [
      { language: 'rust', env: [FOO: 'foo'] }
    ]
  end

  describe 'matrix (2)' do
    yaml %(
      rvm:
      - 2.2
      - 2.3
      gemfile:
      - str
    )

    expands_to [
      { rvm: '2.2', gemfile: 'str' },
      { rvm: '2.3', gemfile: 'str' }
    ]
  end

  describe 'matrix (3)' do
    yaml %(
      env:
        jobs:
        - FOO=foo
        - BAR=bar
        - BAZ=baz
      rvm:
      - 2.2
      - 2.3
      gemfile:
      - str
    )

    expands_to [
      { rvm: '2.2', gemfile: 'str', env: [FOO: 'foo'] },
      { rvm: '2.2', gemfile: 'str', env: [BAR: 'bar'] },
      { rvm: '2.2', gemfile: 'str', env: [BAZ: 'baz'] },
      { rvm: '2.3', gemfile: 'str', env: [FOO: 'foo'] },
      { rvm: '2.3', gemfile: 'str', env: [BAR: 'bar'] },
      { rvm: '2.3', gemfile: 'str', env: [BAZ: 'baz'] }
    ]
  end

  describe 'env strs' do
    yaml %(
    env:
      - FOO=1
      - FOO=2
    )

    expands_to [
      { env: [FOO: '1'] },
      { env: [FOO: '2'] }
    ]
  end

  describe 'env.jobs strs' do
    yaml %(
      env:
        jobs:
        - FOO=foo BAR=bar
        - BAZ=baz
    )

    expands_to [
      { env: [FOO: 'foo', BAR: 'bar'] },
      { env: [BAZ: 'baz'] }
    ]
  end

  describe 'env.jobs hashes' do
    yaml %(
      env:
        jobs:
        - FOO: foo
        - BAR: bar
    )

    expands_to [
      { env: [FOO: 'foo'] },
      { env: [BAR: 'bar'] }
    ]
  end

  describe 'env.jobs one hash' do
    yaml %(
      env:
        jobs:
          FOO: foo
          BAR: bar
    )

    expands_to [
      { env: [FOO: 'foo', BAR: 'bar'] },
    ]
  end

  describe 'env.global' do
    yaml %(
      env:
        global:
          - FOO=foo
      rvm:
      - 2.2
      - 2.3
    )

    expands_to [
      { rvm: '2.2', env: [{ FOO: 'foo' }] },
      { rvm: '2.3', env: [{ FOO: 'foo' }] },
    ]
  end

  describe 'env.jobs and env.global' do
    yaml %(
      env:
        jobs:
          - FOO: foo
          - BAR: bar
        global:
          - BAZ: baz
      rvm:
      - 2.2
      - 2.3
    )

    expands_to [
      { rvm: '2.2', env: [{ BAZ: 'baz' }, { FOO: 'foo' }] },
      { rvm: '2.2', env: [{ BAZ: 'baz' }, { BAR: 'bar' }] },
      { rvm: '2.3', env: [{ BAZ: 'baz' }, { FOO: 'foo' }] },
      { rvm: '2.3', env: [{ BAZ: 'baz' }, { BAR: 'bar' }] }
    ]
  end

  describe 'empty var on env.jobs overwriting env.global' do
    yaml %(
      env:
        global:
        - ONE: one
      jobs:
        include:
          - env: ONE=
    )

    expands_to [
      { env: [{ ONE: 'one' }, { ONE: '' }] },
    ]
  end

  describe 'matrix key unsupported by language' do
    yaml %(
      language: c
      python: 3.7
    )

    expands_to [
      { language: 'c' },
    ]
  end

  describe 'matrix key unsupported by the language does not leave bogus job' do
    yaml %(
      language: shell
      compiler:
        - gcc
        - clang
      matrix:
        include:
          - env: ONE=one
    )

    expands_to [
      { language: 'shell', env: [ONE: 'one'] }
    ]
  end

  describe 'os matrix with no language', defaults: true do
    yaml %(
      os:
      - linux
      - osx
    )

    expands_to [
      { language: 'ruby', os: 'linux', dist: 'focal' },
      { language: 'ruby', os: 'osx' }
    ]
  end

  describe 'osx_image on linux' do
    yaml %(
      os:
      - linux
      - osx
      osx_image:
      - xcode9.4
      - xcode10.2
    )

    expands_to [
      { os: 'linux' },
      { os: 'osx', osx_image: 'xcode9.4' },
      { os: 'osx', osx_image: 'xcode10.2' }
    ]
  end

  describe 'arch on osx' do
    yaml %(
      os:
      - linux
      - osx
      arch:
      - amd64
      - arm64
    )

    expands_to [
      { os: 'linux', arch: 'amd64' },
      { os: 'linux', arch: 'arm64' },
      { os: 'osx' },
    ]
  end

  describe 'arch on windows' do
    yaml %(
      os:
      - linux
      - windows
      arch:
      - amd64
      - arm64
    )

    expands_to [
      { os: 'linux', arch: 'amd64' },
      { os: 'linux', arch: 'arm64' },
      { os: 'windows' },
    ]
  end

  describe 'env and jobs include' do
    yaml %(
      env: FOO=foo
      jobs:
        include:
          - name: one
          - name: two
    )

    expands_to [
      { env: [FOO: 'foo'], name: 'one' },
      { env: [FOO: 'foo'], name: 'two' },
    ]
  end

  describe 'rvm and jobs include' do
    yaml %(
      rvm: 2.5
      jobs:
        include:
          - name: one
          - name: two
    )

    expands_to [
      { rvm: '2.5', name: 'one' },
      { rvm: '2.5', name: 'two' },
    ]
  end

  describe 'jobs include (1)' do
    yaml %(
      env:
        jobs: FOO=foo
      rvm:
      - 2.2
      - 2.3
      jobs:
        include:
          - env: BAR=bar
            rvm: 2.4
    )

    expands_to [
      { env: [FOO: 'foo'], rvm: '2.2' },
      { env: [FOO: 'foo'], rvm: '2.3' },
      { env: [BAR: 'bar'], rvm: '2.4' }
    ]
  end

  describe 'jobs include (2)' do
    yaml %(
      env:
        global:
          FOO: foo
      jobs:
        include:
          - name: one
          - name: two
    )

    expands_to [
      { env: [FOO: 'foo'], name: 'one' },
      { env: [FOO: 'foo'], name: 'two' },
    ]
  end

  describe 'jobs include inheriting a global matrix key' do
    yaml %(
      rvm: 2.4
      jobs:
        include:
          - rvm: 2.2
          - name: str
    )

    expands_to [
      { rvm: '2.2' },
      { rvm: '2.4', name: 'str' }
    ]
  end

  describe 'jobs include inheriting env (legacy)' do
    yaml %(
      env:
        global: FOO=foo
        jobs: BAR=bar
      jobs:
        include:
          - name: one
          - name: two
    )

    expands_to [
      { env: [{ FOO: 'foo' }, { BAR: 'bar' }], name: 'one' },
      { env: [{ FOO: 'foo' }, { BAR: 'bar' }], name: 'two' }
    ]
  end

  describe 'jobs include inheriting env' do
    yaml %(
      env:
        global: FOO=foo
      jobs:
        include:
          - name: one
          - name: two
    )

    expands_to [
      { env: [FOO: 'foo'], name: 'one' },
      { env: [FOO: 'foo'], name: 'two' }
    ]
  end

  describe 'jobs include duplicate' do
    yaml %(
      env:
        jobs: FOO=foo
      rvm:
      - 2.2
      jobs:
        include:
          - env: FOO=foo
            rvm: 2.2
    )

    expands_to [
      { env: [FOO: 'foo'], rvm: '2.2' }
    ]
  end

  describe 'conditional jobs.include' do
    describe 'branch' do
      yaml %(
        jobs:
          include:
            - env: FOO=one
            - env: FOO=two
              if: branch = master
      )

      describe 'matches' do
        let(:data) { { branch: 'master' } }
        expands_to [{ env: [FOO: 'one'] }, { env: [FOO: 'two'], if: 'branch = master' }]
      end

      describe 'does not match' do
        let(:data) { { branch: 'other' } }
        expands_to [{ env: [FOO: 'one'] }]
      end
    end

    describe 'conditional job matching global env' do
      yaml %(
        env:
          global:
            - SLUG=owner/name
        jobs:
          include:
            - name: one
              if:  repo = env(SLUG)
      )

      let(:data) { { repo: 'owner/name' } }

      expands_to [
        { name: 'one', env: [SLUG: 'owner/name'], if: 'repo = env(SLUG)' }
      ]
    end

    describe 'conditional job matching global env with a repo setting present, too' do
      yaml %(
        env:
          global:
            - SLUG=owner/name
        jobs:
          include:
            - name: one
              if:  repo = env(SLUG)
      )

      let(:data) { { repo: 'owner/name', env: [SLUG: 'other'] } }

      expands_to [
        { name: 'one', env: [SLUG: 'owner/name'], if: 'repo = env(SLUG)' }
      ]
    end

    describe 'matches env on job' do
      yaml %(
        jobs:
          include:
            - env: FOO=one
            - env: FOO=two
              if: env(FOO) = two
      )

      expands_to [{ env: [FOO: 'one'] }, { env: [FOO: 'two'], if: 'env(FOO) = two' }]
    end

    describe 'does not match env on job' do
      yaml %(
        jobs:
          include:
            - env: FOO=one
            - env: FOO=two
              if: env(FOO) = one
      )

      expands_to [{ env: [FOO: 'one'] }]
    end

    describe 'matches global.env' do
      yaml %(
        env:
          global:
            - ONE=one

        jobs:
          include:
            - if: env(ONE) IS present
              name: one

            - if: env(ONE) IS present
              name: two
              env:
                - TWO=two
      )

      expands_to [
        { if: 'env(ONE) IS present', name: 'one', env: [{ ONE: 'one' }] },
        { if: 'env(ONE) IS present', name: 'two', env: [{ ONE: 'one' }, { TWO: 'two' }] }
      ]
    end

    describe 'matches settings env var, with env.global present' do
      yaml %(
        env:
          global:
            - GLOBAL=true

        jobs:
          include:
            - name: one
            - name: two
              if: env(SETTING) is present
      )

      let(:data) { { env: [SETTING: true] } }

      expands_to [
        { name: 'one', env: [GLOBAL: 'true'] },
        { name: 'two', env: [GLOBAL: 'true'], if: 'env(SETTING) is present' },
      ]
    end
  end

  describe 'jobs exclude (1)' do
    yaml %(
      env:
        jobs:
        - FOO=foo
        - BAR=bar
      rvm:
      - 2.2
      - 2.3
      jobs:
        exclude:
          - env: BAR=bar
            rvm: 2.3
    )

    expands_to [
      { rvm: '2.2', env: [FOO: 'foo'] },
      { rvm: '2.2', env: [BAR: 'bar'] },
      { rvm: '2.3', env: [FOO: 'foo'] }
    ]
  end

  describe 'jobs exclude (2)' do
    yaml %(
      scala: 2.11.8
      jdk: oraclejdk8
      jobs:
        exclude:
        - scala: 2.11.8
          jdk: oraclejdk8
    )

    expands_to []
  end

  describe 'jobs exclude (3)' do
    yaml %(
      env:
        - FOO=one BAR=one
        - FOO=two BAR=two
      jobs:
        exclude:
          - env: FOO=one BAR=one
    )

    expands_to [env: [FOO: 'two', BAR: 'two']]
  end

  describe 'jobs exclude with global env' do
    yaml %(
      language: python

      python:
        - 3.7

      env:
        global:
          - FOO=foo
        matrix:
          - ONE=one
          - TWO=two

      jobs:
        exclude:
          - env: TWO=two
    )

    expands_to [
      { env: [{ FOO: 'foo' }, { ONE: 'one' }], language: 'python', python: '3.7' }
    ]
  end

  describe 'conditional jobs exclude (1)' do
    yaml %(
      env:
        - FOO=one
        - FOO=two
      jobs:
        exclude:
          - env: FOO=one
            if: true
    )

    expands_to [env: [FOO: 'two']]
  end

  describe 'conditional jobs exclude (2)' do
    yaml %(
      env:
        - FOO=one
        - FOO=two
      jobs:
        exclude:
          - env: FOO=one
            if: false
    )

    expands_to [{ env: [FOO: 'one'] }, { env: [FOO: 'two'] }]
  end

  describe 'conditional jobs exclude matching env' do
    yaml %(
      env:
        - FOO=one
        - FOO=two
      jobs:
        exclude:
          - if: env(FOO) = two
    )

    expands_to [{ env: [FOO: 'one'] }]
  end

  describe 'null env with include' do
    yaml %(
      env:
      rvm:
      - 2.2
      - 2.3
      jobs:
        include:
        - rvm: 1.8.7
          env: FOO=foo
    )

    expands_to [
      { rvm: '2.2' },
      { rvm: '2.3' },
      { rvm: '1.8.7', env: [FOO: 'foo'] }
    ]
  end

  describe 'include as hash' do
    yaml %(
      dist: trusty
      jobs:
        include:
          env: FOO=foo
    )

    expands_to [
      { dist: 'trusty', env: [FOO: 'foo'] }
    ]
  end

  describe 'removes version' do
    yaml %(
      language: shell
      version: '= 0'
    )

    expands_to [
      { language: 'shell' }
    ]
  end

  describe 'stages with matching env vars' do
    yaml %(
      env:
        - ONE=one
        - TWO=two

      jobs:
        include:
          - stage: one
            env: ONE=one
          - env: TWO=two
    )

    expands_to [
      { env: [ONE: 'one'] },
      { env: [TWO: 'two'] },
      { env: [ONE: 'one'], stage: 'one' },
      { env: [TWO: 'two'], stage: 'one' },
    ]
  end

  describe 'python with an os matrix', defaults: true do
    yaml %(
      language: python
      os:
      - linux
      - osx
      - windows
    )

    expands_to [
      { language: 'python', os: 'linux', dist: 'focal' },
      { language: 'python', os: 'osx' },
      { language: 'python', os: 'windows' },
    ]
  end

  describe 'linux-ppc64le and s390x' do
    yaml %(
      language: cpp
      os: linux
      dist: focal

      jobs:
        include:
          - os: linux-ppc64le
          - os: linux
            arch: ppc64le
          - os: linux
            arch: s390x
          - os: linux
            arch: s390x
            dist: bionic
    )

    expands_to [
      { language: 'cpp', os: 'linux-ppc64le', dist: 'focal' },
      { language: 'cpp', os: 'linux', dist: 'focal', arch: 'ppc64le' },
      { language: 'cpp', os: 'linux', dist: 'focal', arch: 's390x' },
      { language: 'cpp', os: 'linux', dist: 'bionic', arch: 's390x' },
    ]
  end

  # describe 'wat' do
  #   yaml %(
  #   )
  #
  #   it { p subject.size }
  # end
end
