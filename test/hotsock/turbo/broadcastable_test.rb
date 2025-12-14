# frozen_string_literal: true

require_relative "../../helper"
require "ostruct"
require "active_model"

describe Hotsock::Turbo::Broadcastable do
  before do
    # Create a test class that includes the Broadcastable concern
    @test_class = Class.new do
      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include Hotsock::Turbo::Broadcastable

      attr_accessor :id

      def initialize(id: 1)
        @id = id
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "TestModel")
      end

      def to_partial_path
        "test_models/test_model"
      end

      def persisted?
        true
      end

      def to_key
        [id]
      end

      def self.after_commit(*)
      end

      def self.after_create_commit(*)
      end

      def self.after_update_commit(*)
      end

      def self.after_destroy_commit(*)
      end
    end

    @instance = @test_class.new
  end

  describe "sync instance methods" do
    it "responds to hotsock_broadcast_refresh" do
      assert_respond_to @instance, :hotsock_broadcast_refresh
    end

    it "responds to hotsock_broadcast_refresh_to" do
      assert_respond_to @instance, :hotsock_broadcast_refresh_to
    end

    it "responds to hotsock_broadcast_remove" do
      assert_respond_to @instance, :hotsock_broadcast_remove
    end

    it "responds to hotsock_broadcast_remove_to" do
      assert_respond_to @instance, :hotsock_broadcast_remove_to
    end

    it "responds to hotsock_broadcast_replace" do
      assert_respond_to @instance, :hotsock_broadcast_replace
    end

    it "responds to hotsock_broadcast_replace_to" do
      assert_respond_to @instance, :hotsock_broadcast_replace_to
    end

    it "responds to hotsock_broadcast_update" do
      assert_respond_to @instance, :hotsock_broadcast_update
    end

    it "responds to hotsock_broadcast_update_to" do
      assert_respond_to @instance, :hotsock_broadcast_update_to
    end

    it "responds to hotsock_broadcast_append" do
      assert_respond_to @instance, :hotsock_broadcast_append
    end

    it "responds to hotsock_broadcast_append_to" do
      assert_respond_to @instance, :hotsock_broadcast_append_to
    end

    it "responds to hotsock_broadcast_prepend" do
      assert_respond_to @instance, :hotsock_broadcast_prepend
    end

    it "responds to hotsock_broadcast_prepend_to" do
      assert_respond_to @instance, :hotsock_broadcast_prepend_to
    end

    it "responds to hotsock_broadcast_before_to" do
      assert_respond_to @instance, :hotsock_broadcast_before_to
    end

    it "responds to hotsock_broadcast_after_to" do
      assert_respond_to @instance, :hotsock_broadcast_after_to
    end

    it "responds to hotsock_broadcast_action" do
      assert_respond_to @instance, :hotsock_broadcast_action
    end

    it "responds to hotsock_broadcast_action_to" do
      assert_respond_to @instance, :hotsock_broadcast_action_to
    end

    it "responds to hotsock_broadcast_render" do
      assert_respond_to @instance, :hotsock_broadcast_render
    end

    it "responds to hotsock_broadcast_render_to" do
      assert_respond_to @instance, :hotsock_broadcast_render_to
    end

    it "hotsock_broadcast_refresh calls StreamsChannel.broadcast_refresh_to with self" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_to, ->(*streamables, **attributes) do
        called = true
        assert_equal [@instance], streamables
      end do
        @instance.hotsock_broadcast_refresh
      end
      assert called, "broadcast_refresh_to was not called"
    end

    it "hotsock_broadcast_refresh_to calls StreamsChannel.broadcast_refresh_to with given streamables" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_to, ->(*streamables, **attributes) do
        called = true
        assert_equal ["custom_stream", :messages], streamables
      end do
        @instance.hotsock_broadcast_refresh_to("custom_stream", :messages)
      end
      assert called, "broadcast_refresh_to was not called"
    end

    it "hotsock_broadcast_remove_to calls StreamsChannel.broadcast_remove_to" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_remove_to, ->(*streamables, target:) do
        called = true
        assert_equal ["stream"], streamables
        assert_equal "test_model_1", target
      end do
        @instance.hotsock_broadcast_remove_to("stream")
      end
      assert called, "broadcast_remove_to was not called"
    end

    it "hotsock_broadcast_before_to raises without target or targets" do
      assert_raises(ArgumentError) do
        @instance.hotsock_broadcast_before_to("stream")
      end
    end

    it "hotsock_broadcast_after_to raises without target or targets" do
      assert_raises(ArgumentError) do
        @instance.hotsock_broadcast_after_to("stream")
      end
    end
  end

  describe "async instance methods" do
    it "responds to hotsock_broadcast_refresh_later" do
      assert_respond_to @instance, :hotsock_broadcast_refresh_later
    end

    it "responds to hotsock_broadcast_refresh_later_to" do
      assert_respond_to @instance, :hotsock_broadcast_refresh_later_to
    end

    it "responds to hotsock_broadcast_replace_later" do
      assert_respond_to @instance, :hotsock_broadcast_replace_later
    end

    it "responds to hotsock_broadcast_replace_later_to" do
      assert_respond_to @instance, :hotsock_broadcast_replace_later_to
    end

    it "responds to hotsock_broadcast_update_later" do
      assert_respond_to @instance, :hotsock_broadcast_update_later
    end

    it "responds to hotsock_broadcast_update_later_to" do
      assert_respond_to @instance, :hotsock_broadcast_update_later_to
    end

    it "responds to hotsock_broadcast_append_later" do
      assert_respond_to @instance, :hotsock_broadcast_append_later
    end

    it "responds to hotsock_broadcast_append_later_to" do
      assert_respond_to @instance, :hotsock_broadcast_append_later_to
    end

    it "responds to hotsock_broadcast_prepend_later" do
      assert_respond_to @instance, :hotsock_broadcast_prepend_later
    end

    it "responds to hotsock_broadcast_prepend_later_to" do
      assert_respond_to @instance, :hotsock_broadcast_prepend_later_to
    end

    it "responds to hotsock_broadcast_action_later" do
      assert_respond_to @instance, :hotsock_broadcast_action_later
    end

    it "responds to hotsock_broadcast_action_later_to" do
      assert_respond_to @instance, :hotsock_broadcast_action_later_to
    end

    it "responds to hotsock_broadcast_render_later" do
      assert_respond_to @instance, :hotsock_broadcast_render_later
    end

    it "responds to hotsock_broadcast_render_later_to" do
      assert_respond_to @instance, :hotsock_broadcast_render_later_to
    end

    it "hotsock_broadcast_refresh_later calls StreamsChannel.broadcast_refresh_later_to with self" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_later_to, ->(*streamables, **attributes) do
        called = true
        assert_equal [@instance], streamables
      end do
        @instance.hotsock_broadcast_refresh_later
      end
      assert called, "broadcast_refresh_later_to was not called"
    end

    it "hotsock_broadcast_refresh_later_to calls StreamsChannel.broadcast_refresh_later_to with given streamables" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_later_to, ->(*streamables, **attributes) do
        called = true
        assert_equal ["custom_stream", :messages], streamables
      end do
        @instance.hotsock_broadcast_refresh_later_to("custom_stream", :messages)
      end
      assert called, "broadcast_refresh_later_to was not called"
    end
  end

  describe "class methods" do
    it "responds to hotsock_broadcasts" do
      assert_respond_to @test_class, :hotsock_broadcasts
    end

    it "responds to hotsock_broadcasts_to" do
      assert_respond_to @test_class, :hotsock_broadcasts_to
    end

    it "responds to hotsock_broadcasts_refreshes" do
      assert_respond_to @test_class, :hotsock_broadcasts_refreshes
    end

    it "responds to hotsock_broadcasts_refreshes_to" do
      assert_respond_to @test_class, :hotsock_broadcasts_refreshes_to
    end

    it "responds to hotsock_broadcast_target_default" do
      assert_respond_to @test_class, :hotsock_broadcast_target_default
    end

    it "hotsock_broadcast_target_default returns model plural name" do
      assert_equal "test_models", @test_class.hotsock_broadcast_target_default
    end

    it "responds to suppressing_turbo_broadcasts" do
      assert_respond_to @test_class, :suppressing_turbo_broadcasts
    end

    it "responds to suppressed_turbo_broadcasts?" do
      assert_respond_to @test_class, :suppressed_turbo_broadcasts?
    end
  end

  describe "suppressing_turbo_broadcasts" do
    it "suppresses broadcasts within block" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_to, ->(*args, **kwargs) do
        called = true
      end do
        @test_class.suppressing_turbo_broadcasts do
          @instance.hotsock_broadcast_refresh
        end
      end
      refute called, "broadcast_refresh_to should not have been called"
    end

    it "allows broadcasts outside block" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_to, ->(*args, **kwargs) do
        called = true
      end do
        @test_class.suppressing_turbo_broadcasts do
          # Do nothing
        end
        @instance.hotsock_broadcast_refresh
      end
      assert called, "broadcast_refresh_to should have been called"
    end

    it "suppressed_turbo_broadcasts? is true within block" do
      @test_class.suppressing_turbo_broadcasts do
        assert @instance.suppressed_turbo_broadcasts?
      end
    end

    it "suppressed_turbo_broadcasts? is false outside block" do
      refute @instance.suppressed_turbo_broadcasts?
    end

    it "suppresses sync broadcast methods" do
      methods_called = []

      Hotsock::Turbo::StreamsChannel.stub :broadcast_remove_to, ->(*args, **kwargs) { methods_called << :remove } do
        Hotsock::Turbo::StreamsChannel.stub :broadcast_action_to, ->(*args, **kwargs) { methods_called << :action } do
          Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_to, ->(*args, **kwargs) { methods_called << :refresh } do
            @test_class.suppressing_turbo_broadcasts do
              @instance.hotsock_broadcast_remove_to("stream")
              @instance.hotsock_broadcast_replace_to("stream")
              @instance.hotsock_broadcast_refresh_to("stream")
            end
          end
        end
      end

      assert_empty methods_called, "No broadcast methods should have been called"
    end

    it "suppresses async broadcast methods" do
      methods_called = []

      Hotsock::Turbo::StreamsChannel.stub :broadcast_replace_later_to, ->(*args, **kwargs) { methods_called << :replace_later } do
        Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_later_to, ->(*args, **kwargs) { methods_called << :refresh_later } do
          @test_class.suppressing_turbo_broadcasts do
            @instance.hotsock_broadcast_replace_later_to("stream")
            @instance.hotsock_broadcast_refresh_later_to("stream")
          end
        end
      end

      assert_empty methods_called, "No broadcast methods should have been called"
    end
  end
end

describe Hotsock::Turbo::Broadcastable::TurboBroadcastableOverride do
  before do
    # Create a test class that includes both modules
    @test_class = Class.new do
      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include Hotsock::Turbo::Broadcastable
      include Hotsock::Turbo::Broadcastable::TurboBroadcastableOverride

      attr_accessor :id

      def initialize(id: 1)
        @id = id
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "TestModel")
      end

      def to_partial_path
        "test_models/test_model"
      end

      def persisted?
        true
      end

      def to_key
        [id]
      end

      def self.after_commit(*)
      end

      def self.after_create_commit(*)
      end

      def self.after_update_commit(*)
      end

      def self.after_destroy_commit(*)
      end
    end

    @instance = @test_class.new
  end

  describe "override class methods" do
    it "responds to broadcasts" do
      assert_respond_to @test_class, :broadcasts
    end

    it "responds to broadcasts_to" do
      assert_respond_to @test_class, :broadcasts_to
    end

    it "responds to broadcasts_refreshes" do
      assert_respond_to @test_class, :broadcasts_refreshes
    end

    it "responds to broadcasts_refreshes_to" do
      assert_respond_to @test_class, :broadcasts_refreshes_to
    end

    it "broadcast_target_default delegates to hotsock_broadcast_target_default" do
      assert_equal @test_class.hotsock_broadcast_target_default, @test_class.broadcast_target_default
    end
  end

  describe "override sync instance methods" do
    it "broadcast_refresh delegates to hotsock_broadcast_refresh" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_to, ->(*args, **kwargs) do
        called = true
      end do
        @instance.broadcast_refresh
      end
      assert called, "hotsock_broadcast_refresh should have been called"
    end

    it "broadcast_refresh_to delegates to hotsock_broadcast_refresh_to" do
      called_with = nil
      Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_to, ->(*streamables, **attrs) do
        called_with = streamables
      end do
        @instance.broadcast_refresh_to("custom_stream")
      end
      assert_equal ["custom_stream"], called_with
    end

    it "broadcast_remove_to delegates to hotsock_broadcast_remove_to" do
      called_with = nil
      Hotsock::Turbo::StreamsChannel.stub :broadcast_remove_to, ->(*streamables, **kwargs) do
        called_with = streamables
      end do
        @instance.broadcast_remove_to("stream")
      end
      assert_equal ["stream"], called_with
    end

    it "broadcast_replace_to delegates to hotsock_broadcast_replace_to" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_action_to, ->(*args, **kwargs) do
        called = true
      end do
        @instance.broadcast_replace_to("stream")
      end
      assert called
    end

    it "broadcast_append_to delegates to hotsock_broadcast_append_to" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_action_to, ->(*args, **kwargs) do
        called = true
      end do
        @instance.broadcast_append_to("stream")
      end
      assert called
    end
  end

  describe "override async instance methods" do
    it "broadcast_refresh_later delegates to hotsock_broadcast_refresh_later" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_later_to, ->(*args, **kwargs) do
        called = true
      end do
        @instance.broadcast_refresh_later
      end
      assert called
    end

    it "broadcast_replace_later_to delegates to hotsock_broadcast_replace_later_to" do
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_replace_later_to, ->(*args, **kwargs) do
        called = true
      end do
        @instance.broadcast_replace_later_to("stream")
      end
      assert called
    end
  end

  describe "prepend takes precedence over later includes" do
    it "override methods take precedence even when a competing module is included after" do
      # Simulate Turbo::Broadcastable being included after our override
      competing_module = Module.new do
        def broadcast_refresh
          :turbo_version
        end
      end

      # Create a test class that prepends our override, then includes the competing module
      test_class = Class.new do
        extend ActiveModel::Naming
        include ActiveModel::Conversion
        include Hotsock::Turbo::Broadcastable
        prepend Hotsock::Turbo::Broadcastable::TurboBroadcastableOverride
        include competing_module  # This simulates turbo-rails including Turbo::Broadcastable

        def self.model_name
          ActiveModel::Name.new(self, nil, "TestModel")
        end

        def to_partial_path
          "test_models/test_model"
        end

        def to_key
          [1]
        end
      end

      instance = test_class.new

      # Our prepended override should take precedence
      called = false
      Hotsock::Turbo::StreamsChannel.stub :broadcast_refresh_to, ->(*args, **kwargs) do
        called = true
      end do
        instance.broadcast_refresh
      end

      assert called, "Hotsock override should take precedence over competing module"
    end
  end
end
