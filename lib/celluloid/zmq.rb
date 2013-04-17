require 'ffi-rzmq'

require 'celluloid/io'
require 'celluloid/zmq/mailbox'
require 'celluloid/zmq/reactor'
require 'celluloid/zmq/sockets'
require 'celluloid/zmq/version'
require 'celluloid/zmq/waker'

module Celluloid
  # Actors which run alongside 0MQ sockets
  module ZMQ
    class << self
      attr_writer :context

      # Included hook to pull in Celluloid
      def included(klass)
        klass.send :include, ::Celluloid
        klass.mailbox_class Celluloid::ZMQ::Mailbox
      end

      # Obtain a 0MQ context (or lazily initialize it)
      def context(worker_threads = 1)
        return @context if @context
        @context = ::ZMQ::Context.new(worker_threads)
      end
      alias_method :init, :context

      def terminate
        @context.terminate
      end
    end

    # Is this a Celluloid::ZMQ evented actor?
    def evented?
      actor = Thread.current[:celluloid_actor]
      return unless actor

      mailbox = actor.mailbox
      mailbox.is_a?(Celluloid::IO::Mailbox) && mailbox.reactor.is_a?(Celluloid::ZMQ::Reactor)
    end

    def wait_readable(socket)
      throw TypeError unless ZMQ.evented?
      throw ArgumentError unless socket.is_a?(::ZMQ::Socket)
      actor = Thread.current[:celluloid_actor]
      actor.mailbox.reactor.wait_readable(socket)
      nil
    end

  end
end
