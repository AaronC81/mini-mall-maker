module GosuGameJam3
  module Res
    ROOT = File.join(__dir__, '..', 'res')

    def self.image(*name)
      @@loaded_images ||= {}
      @@loaded_images[name] ||= Gosu::Image.new(File.join(ROOT, *name))
      @@loaded_images[name]
    end

    def self.sample(*name)
      @@loaded_samples ||= {}
      @@loaded_samples[name] ||= Gosu::Sample.new(File.join(ROOT, *name))
      @@loaded_samples[name]
    end

    def self.song(*name)
      @@loaded_songs ||= {}
      @@loaded_songs[name] ||= Gosu::Song.new(File.join(ROOT, *name))
      @@loaded_songs[name].volume = 0.15
      @@loaded_songs[name].volume = 0 if ENV['NO_MUSIC']
      @@loaded_songs[name]
    end
  end
end
