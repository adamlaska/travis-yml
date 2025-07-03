describe Travis::Yml::Configs, 'merging env' do
  let(:repo) { { id: 1, github_id: 1, slug: 'travis-ci/travis-yml', private: false, token: 'token', private_key: 'key', allow_config_imports: true } }

  before { stub_content(repo[:id], '.travis.yml', travis_yml) }
  before { stub_content(repo[:id], 'one.yml', one) }
  before { stub_content(repo[:id], 'two.yml', two) }

  subject { described_class.new(repo, 'master', api ? [config: api, mode: mode] : nil, {}, opts).tap(&:load) }

  let(:travis_yml) do
    %(
      import:
      - source: one.yml
        mode: #{mode}
      script: ./travis
      env: TRAVIS=true
    )
  end

  let(:one) do
    %(
      os: linux
      import:
      - source: two.yml
        mode: #{mode}
      script: ./one
      env: ONE=true
    )
  end

  let(:two) do
    %(
      script: ./two
    )
  end

  describe 'merge_normalized turned off' do
    describe '.travis.yml' do
      let(:api) { nil }

      describe 'deep_merge_append' do
        let(:mode) { :deep_merge_append }
        it do
          should serialize_to(
            os: ['linux'],
            script: %w(./travis),
            env: { jobs: [{ TRAVIS: 'true' }] }
          )
        end
      end

      describe 'deep_merge_prepend' do
        let(:mode) { :deep_merge_prepend }
        it do
          should serialize_to(
            os: ['linux'],
            script: %w(./travis),
            env: { jobs: [{ TRAVIS: 'true' }] }
          )
        end
      end

      describe 'deep_merge' do
        let(:mode) { :deep_merge }
        it do
          should serialize_to(
            os: ['linux'],
            script: %w(./travis),
            env: { jobs: [{ TRAVIS: 'true' }] }
          )
        end
      end

      describe 'replace' do
        let(:mode) { :replace }
        it do
          should serialize_to(
            script: %w(./travis),
            env: { jobs: [{ TRAVIS: 'true' }] }
          )
        end
      end
    end

    describe 'api' do
      let(:api) do
        %(
          dist: focal
          script: ./api
          env: API=true
        )
      end

      describe 'deep_merge_append' do
        let(:mode) { :deep_merge_append }
        it do
          should serialize_to(
            os: ['linux'],
            dist: 'focal',
            script: %w(./api),
            env: { jobs: [{ API: 'true' }] }
          )
        end
      end

      describe 'deep_merge_prepend' do
        let(:mode) { :deep_merge_prepend }
        it do
          should serialize_to(
            os: ['linux'],
            dist: 'focal',
            script: %w(./api),
            env: { jobs: [{ API: 'true' }] }
          )
        end
      end

      describe 'deep_merge' do
        let(:mode) { :deep_merge }
        it do
          should serialize_to(
            os: ['linux'],
            dist: 'focal',
            script: %w(./api),
            env: { jobs: [{ API: 'true' }] }
          )
        end
      end

      describe 'replace' do
        let(:mode) { :replace }
        it do
          should serialize_to(
            dist: 'focal',
            script: %w(./api),
            env: { jobs: [{ API: 'true' }] }
          )
        end
      end
    end

    describe 'api (empty)', defaults: true do
      let(:api) { '' }

      describe 'replace' do
        let(:mode) { :replace }
        it { should serialize_to defaults }
      end
    end
  end

  describe 'merge_normalized turned on', merge_normalized: true do
    describe '.travis.yml' do
      let(:api) { nil }

      describe 'deep_merge_append' do
        let(:mode) { :deep_merge_append }
        it do
          should serialize_to(
            os: ['linux'],
            script: %w(./two ./one ./travis),
            env: { jobs: [{ ONE: 'true' }, { TRAVIS: 'true' }] }
          )
        end
      end

      describe 'deep_merge_prepend' do
        let(:mode) { :deep_merge_prepend }
        it do
          should serialize_to(
            os: ['linux'],
            script: %w(./travis ./one ./two),
            env: { jobs: [{ TRAVIS: 'true' }, { ONE: 'true' }] }
          )
        end
      end

      describe 'deep_merge' do
        let(:mode) { :deep_merge }
        it do
          should serialize_to(
            os: ['linux'],
            script: %w(./travis),
            env: { jobs: [{ TRAVIS: 'true' }] }
          )
        end
      end

      describe 'replace' do
        let(:mode) { :replace }
        it do
          should serialize_to(
            script: %w(./travis),
            env: { jobs: [{ TRAVIS: 'true' }] }
          )
        end
      end
    end

    describe 'api' do
      let(:api) do
        %(
          dist: focal
          script: ./api
          env: API=true
        )
      end

      describe 'deep_merge_append' do
        let(:mode) { :deep_merge_append }
        it do
          should serialize_to(
            os: ['linux'],
            dist: 'focal',
            script: %w(./two ./one ./travis ./api),
            env: { jobs: [{ ONE: 'true' }, { TRAVIS: 'true' }, { API: 'true' }] }
          )
        end
      end

      describe 'deep_merge_prepend' do
        let(:mode) { :deep_merge_prepend }
        it do
          should serialize_to(
            os: ['linux'],
            dist: 'focal',
            script: %w(./api ./travis ./one ./two),
            env: { jobs: [{ API: 'true' }, { TRAVIS: 'true' }, { ONE: 'true' }] }
          )
        end
      end

      describe 'deep_merge' do
        let(:mode) { :deep_merge }
        it do
          should serialize_to(
            os: ['linux'],
            dist: 'focal',
            script: %w(./api),
            env: { jobs: [{ API: 'true' }] }
          )
        end
      end

      describe 'replace' do
        let(:mode) { :replace }
        it do
          should serialize_to(
            dist: 'focal',
            script: %w(./api),
            env: { jobs: [{ API: 'true' }] }
          )
        end
      end
    end
  end
end
