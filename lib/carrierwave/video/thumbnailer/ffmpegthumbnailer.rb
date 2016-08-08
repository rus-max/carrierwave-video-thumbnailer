require 'carrierwave/video/thumbnailer/ffmpegthumbnailer/options'
require 'open3'
require 'mini_magick'

module CarrierWave
  module Video
    module Thumbnailer
      class FFMpegThumbnailer

        # Explicit class methods
        class << self

          # Sets a required thumbnailer binary
          def binary=(bin)
            @ffmpegthumbnailer = bin
          end

          # Tells the thumbnailer binary name
          def binary
            @ffmpegthumbnailer.nil? ? 'ffmpegthumbnailer' : @ffmpegthumbnailer
          end

          def logger= log
            @logger = log
          end

          def logger
            return @logger if @logger
            logger = Logger.new(STDOUT)
            logger.level = Logger::INFO
            @logger = logger
          end
        end

        attr_reader :input_path, :output_path

        def initialize in_path, out_path
          @input_path  = in_path
          @output_path = out_path
        end

        def run options
          logger = options.logger
          logger.info(input_path) if logger
          logger.info(output_path) if logger

          resolution = options.options.dig(:screenshot, :resolution) || '300x300'

          movie = ::FFMPEG::Movie.new(input_path)
          movie.screenshot(output_path, { resolution: resolution }, preserve_aspect_ratio: :width)
          mini_magick_opts = options.options[:mini_magick_opts]
          if mini_magick_opts.is_a?(Proc)
            mini_magick_opts.call(::MiniMagick::Image.new("#{output_path}"), input_path)
          end
        end

        private

        def handle_exit_code(exit_code, outputs, logger)
          return unless logger
          if exit_code == 0
            logger.info("Success!")
          else
            outputs.each do |output|
              logger.error(output)
            end
            logger.error("Failure!")
          end
          exit_code
        end

      end
    end
  end
end
