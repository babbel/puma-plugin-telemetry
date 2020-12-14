# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      # Helper for working with Puma stats
      module CommonData
        TELEMETRY_TO_METHODS = {
          "workers.booted" => :workers_booted,
          "workers.total" => :workers_total,
          "workers.spawned_threads" => :workers_spawned_threads,
          "workers.max_threads" => :workers_max_threads,
          "workers.requests_count" => :workers_requests_count,
          "queue.backlog" => :queue_backlog,
          "queue.capacity" => :queue_capacity
        }.freeze

        def initialize(stats)
          @stats = stats
        end

        def workers_booted
          @stats.fetch(:booted_workers, 1)
        end

        def workers_total
          @stats.fetch(:workers, 1)
        end

        def metrics(selected)
          selected.each_with_object({}) do |metric, obj|
            next unless TELEMETRY_TO_METHODS.key?(metric)

            obj[metric] = public_send(TELEMETRY_TO_METHODS[metric])
          end
        end
      end

      # Handles the case of non clustered mode, where `workers` isn't configured
      class WorkerData
        include CommonData

        def workers_max_threads
          @stats.fetch(:max_threads, 0)
        end

        def workers_requests_count
          @stats.fetch(:requests_count, 0)
        end

        def workers_spawned_threads
          @stats.fetch(:running, 0)
        end

        def queue_backlog
          @stats.fetch(:backlog, 0)
        end

        def queue_capacity
          @stats.fetch(:pool_capacity, 0)
        end
      end

      # Handles the case of clustered mode, where we have statistics
      # for all the workers. This class takes care of summing all
      # relevant data.
      class ClusteredData
        include CommonData

        def workers_max_threads
          sum_stat(:max_threads)
        end

        def workers_requests_count
          sum_stat(:requests_count)
        end

        def workers_spawned_threads
          sum_stat(:running)
        end

        def queue_backlog
          sum_stat(:backlog)
        end

        def queue_capacity
          sum_stat(:pool_capacity)
        end

        private

        def sum_stat(stat)
          @stats[:worker_status].reduce(0) do |sum, data|
            (data.dig(:last_status, stat) || 0) + sum
          end
        end
      end
    end
  end
end
