describe Travis::Yml do
  accept 'dist' do
    describe 'no default' do
      yaml ''
      it { should serialize_to empty }
    end

    known = %w(
      precise
      trusty
      xenial
      focal
      jammy
      noble
    )

    known.each do |value|
      describe "given #{value}" do
        yaml %(
          dist: #{value}
        )
        it { should serialize_to dist: value }
        it { should_not have_msg }
      end
    end

    describe 'default', defaults: true do
      describe 'no os given', defaults: true do
        yaml ''
        it { should serialize_to os: ['linux'], dist: 'focal', language: 'ruby' }
        it { should have_msg [:info, :root, :default, key: 'dist', default: 'focal'] }
      end

      describe 'on linux', defaults: true do
        yaml %(
          os: linux
        )
        it { should serialize_to os: ['linux'], dist: 'focal', language: 'ruby' }
        it { should have_msg [:info, :root, :default, key: 'dist', default: 'focal'] }
      end

      describe 'on windows', defaults: true do
        yaml %(
          language: shell
          os: windows
        )
        it { should serialize_to os: ['windows'], language: 'shell' }
        it { should_not have_msg }
      end

      describe 'on oxs', defaults: true do
        yaml %(
          language: ruby
          os: osx
        )
        it { should serialize_to os: ['osx'], language: 'ruby' }
        it { should_not have_msg }
      end
    end

    describe 'ignores case' do
      yaml %(
        dist: TRUSTY
      )
      it { should serialize_to dist: 'trusty' }
      it { should have_msg [:info, :dist, :downcase, value: 'TRUSTY'] }
    end

    describe 'given an unknown value' do
      yaml %(
        dist: unknown
      )
      it { should serialize_to dist: 'unknown' }
      it { should have_msg [:error, :dist, :unknown_value, value: 'unknown'] }
    end

    describe 'given a seq' do
      yaml %(
        dist:
        - trusty
      )
      it { should serialize_to dist: 'trusty' }
      it { should have_msg [:warn, :dist, :unexpected_seq, value: 'trusty'] }
    end

    describe 'unsupported on osx' do
      yaml %(
        os:
        - osx
        dist:
        - trusty
      )
      it { should serialize_to os: ['osx'], dist: 'trusty' }
      it { should have_msg [:warn, :dist, :unsupported, on_key: 'os', on_value: 'osx', key: 'dist', value: 'trusty'] }
    end
  end
end
