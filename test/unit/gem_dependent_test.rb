require 'test_helper'

class GemDependentTest < ActiveSupport::TestCase
  context "creating a new dependency_api" do
    setup do
      @gem = create(:rubygem)
      @gem_dependent = GemDependent.new(@gem.name)
    end

    should "have some state" do
      assert @gem_dependent.respond_to?(:gem_names)
    end
  end

  context "no gem_names" do
    should "return an ArgumentError" do
      assert_raises ArgumentError do
        GemDependent.new.to_a
      end
    end
  end

  context "with gem_names" do
    context "no dependencies" do
      setup do
        @gem = create(:rubygem, name: "rack")
        create(:version, number: "0.0.1", rubygem_id: @gem.id)
        create(:version, number: "0.0.2", rubygem_id: @gem.id)
      end

      should "return all versions for a gem" do
        deps = GemDependent.new(["rack"]).to_a
        assert_equal(
          [
            { name: "rack", number: "0.0.1", platform: "ruby", dependencies: [] },
            { name: "rack", number: "0.0.2", platform: "ruby", dependencies: [] }
          ],
          deps
        )
      end
    end

    context "has one dependency" do
      setup do
        rack = create(:rubygem, name: "rack")
        version = create(:version, number: "0.0.1", rubygem_id: rack.id)
        create(:version, number: "0.2.0", rubygem_id: rack.id)
        create(:version, number: "1.0.1", rubygem_id: rack.id)

        rubygem        = create(:rubygem, name: "foo")
        gem_dependency = Gem::Dependency.new(rubygem.name, ['>= 0.0.0'])
        create(:dependency, rubygem: rubygem, version: version, gem_dependency: gem_dependency)
      end

      should "return foo as a dep of rack" do
        result = {
          name:         'rack',
          number:       '0.0.1',
          dependencies: [['foo', '>= 0.0.0']]
        }

        dep = GemDependent.new(["rack"]).to_a.first
        result.each_pair do |k, v|
          assert_equal v, dep[k]
        end
      end
    end
  end

  context "with gem_names which do not exist" do
    should "return empty array" do
      assert_equal [], GemDependent.new(["does_not_exist"]).to_a
    end
  end
end
