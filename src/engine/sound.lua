--- The sound class. This is a transparent wrapper over Love2D's `Source`.
---@class Sound
---
---@field private source love.Source
---@field private settings Assets.sound_settings
---@field private volume number
---@field private set_volume number
---
---@overload fun(source: love.Source, settings: Assets.sound_settings): Sound
local Sound = Class()

---@param source love.Source
---@param settings Assets.sound_settings?
function Sound:init(source, settings)
    self.settings = settings or {}

    self.source = source
    self.volume = self.settings.volume or 1

    self.source:setVolume(self.volume)

    self.set_volume = 1
end

--- Creates an identical copy of the Sound in the stopped state.
--- 
--- Static Sounds will use significantly less memory and take much less time to be created if Sound:clone is used to create them instead of love.audio.newSource, so this method should be preferred when making multiple Sounds which play the same sound.
---@return Sound
function Sound:clone()
    local sound = Sound(self.source:clone(), self.settings)
    sound.set_volume = self.set_volume
    sound.source:setVolume(sound.volume * sound.set_volume)
    return sound
end

--- Gets a list of the Sound's active effect names.
---@return table
function Sound:getActiveEffects()
    return self.source:getActiveEffects()
end

--- Gets the amount of air absorption applied to the Sound.
--- 
--- By default the value is set to 0 which means that air absorption effects are disabled. A value of 1 will apply high frequency attenuation to the Sound at a rate of 0.05 dB per meter.
---@return number
function Sound:getAirAbsorption()
    return self.source:getAirAbsorption()
end

--- Gets the reference and maximum attenuation distances of the Sound. The values, combined with the current DistanceModel, affect how the Sound's volume attenuates based on distance from the listener.
---@return number, number
function Sound:getAttenuationDistances()
    return self.source:getAttenuationDistances()
end

--- Gets the number of channels in the Sound. Only 1-channel (mono) Sounds can use directional and positional effects.
---@return number
function Sound:getChannelCount()
    return self.source:getChannelCount()
end

--- Gets the Sound's directional volume cones. Together with Sound:setDirection, the cone angles allow for the Sound's volume to vary depending on its direction.
---@return number, number, number
function Sound:getCone()
    return self.source:getCone()
end

--- Gets the direction of the Sound.
---@return number, number, number
function Sound:getDirection()
    return self.source:getDirection()
end

--- Gets the duration of the Sound. For streaming Sounds it may not always be sample-accurate, and may return -1 if the duration cannot be determined at all.
---@param unit love.TimeUnit? # The time unit for the return value. (Defaults to 'seconds'.)
---@return number
function Sound:getDuration(unit)
    return self.source:getDuration(unit)
end

--- Gets the filter settings associated to a specific effect.
--- 
--- This function returns nil if the effect was applied with no filter settings associated to it.
---@param name string # The name of the effect.
---@param filtersettings table? # An optional empty table that will be filled with the filter settings. (Defaults to {}.)
---@return table
function Sound:getEffect(name, filtersettings)
    return self.source:getEffect(name, filtersettings)
end

--- Gets the filter settings currently applied to the Sound.
---@return table
function Sound:getFilter()
    return self.source:getFilter()
end

--- Gets the number of free buffer slots in a queueable Sound. If the queueable Sound is playing, this value will increase up to the amount the Sound was created with. If the queueable Sound is stopped, it will process all of its internal buffers first, in which case this function will always return the amount it was created with.
---@return number
function Sound:getFreeBufferCount()
    return self.source:getFreeBufferCount()
end

--- Gets the current pitch of the Sound.
---@return number
function Sound:getPitch()
    return self.source:getPitch()
end

--- Gets the position of the Sound.
---@return number, number, number
function Sound:getPosition()
    return self.source:getPosition()
end

--- Returns the rolloff factor of the source.
---@return number
function Sound:getRolloff()
    return self.source:getRolloff()
end

--- Gets the type of the Sound.
---@return love.SourceType
function Sound:getType()
    return self.source:getType()
end

--- Gets the velocity of the Sound.
---@return number, number, number
function Sound:getVelocity()
    return self.source:getVelocity()
end

--- Gets the current volume of the Sound.
---@return number
function Sound:getVolume()
    return self.set_volume
end

--- Returns the volume limits of the source.
---@return number, number
function Sound:getVolumeLimits()
    return self.source:getVolumeLimits()
end

--- Returns whether the Sound will loop.
---@return boolean
function Sound:isLooping()
    return self.source:isLooping()
end

--- Returns whether the Sound is playing.
---@return boolean
function Sound:isPlaying()
    return self.source:isPlaying()
end

--- Gets whether the Sound's position, velocity, direction, and cone angles are relative to the listener.
---@return boolean
function Sound:isRelative()
    return self.source:isRelative()
end

--- Pauses the Sound.
function Sound:pause()
    self.source:pause()
end

--- Starts playing the Sound.
---@return boolean
function Sound:play()
    return self.source:play()
end

--- Queues SoundData for playback in a queueable Sound.
--- 
--- This method requires the Sound to be created via love.audio.newQueueableSource.
---@param sounddata love.SoundData # The data to queue. The SoundData's sample rate, bit depth, and channel count must match the Sound's.
---@return boolean
function Sound:queue(sounddata)
    return self.source:queue(sounddata)
end

--- Sets the currently playing position of the Sound.
---@param offset number # The position to seek to.
---@param unit love.TimeUnit? # The unit of the position value. (Defaults to 'seconds'.)
function Sound:seek(offset, unit)
    self.source:seek(offset, unit)
end

--- Sets the amount of air absorption applied to the Sound.
--- 
--- By default the value is set to 0 which means that air absorption effects are disabled. A value of 1 will apply high frequency attenuation to the Sound at a rate of 0.05 dB per meter.
--- 
--- Air absorption can simulate sound transmission through foggy air, dry air, smoky atmosphere, etc. It can be used to simulate different atmospheric conditions within different locations in an area.
---@param amount number # The amount of air absorption applied to the Sound. Must be between 0 and 10.
function Sound:setAirAbsorption(amount)
    self.source:setAirAbsorption(amount)
end

--- Sets the reference and maximum attenuation distances of the Sound. The parameters, combined with the current DistanceModel, affect how the Sound's volume attenuates based on distance.
--- 
--- Distance attenuation is only applicable to Sounds based on mono (rather than stereo) audio.
---@param ref number # The new reference attenuation distance. If the current DistanceModel is clamped, this is the minimum attenuation distance.
---@param max number # The new maximum attenuation distance.
function Sound:setAttenuationDistances(ref, max)
    self.source:setAttenuationDistances(ref, max)
end

--- Sets the Sound's directional volume cones. Together with Sound:setDirection, the cone angles allow for the Sound's volume to vary depending on its direction.
---@param innerAngle number # The inner angle from the Sound's direction, in radians. The Sound will play at normal volume if the listener is inside the cone defined by this angle.
---@param outerAngle number # The outer angle from the Sound's direction, in radians. The Sound will play at a volume between the normal and outer volumes, if the listener is in between the cones defined by the inner and outer angles.
---@param outerVolume number? # The Sound's volume when the listener is outside both the inner and outer cone angles. (Defaults to 0.)
function Sound:setCone(innerAngle, outerAngle, outerVolume)
    self.source:setCone(innerAngle, outerAngle, outerVolume)
end

--- Sets the direction vector of the Sound. A zero vector makes the source non-directional.
---@param x number # The X part of the direction vector.
---@param y number # The Y part of the direction vector.
---@param z number # The Z part of the direction vector.
function Sound:setDirection(x, y, z)
    self.source:setDirection(x, y, z)
end

--- Applies an audio effect to the Sound.
--- 
--- The effect must have been previously defined using love.audio.setEffect.
---@param name string # The name of the effect previously set up with love.audio.setEffect.
---@param enable boolean? # If false and the given effect name was previously enabled on this Sound, disables the effect. (Defaults to true.)
---@return boolean
---@overload fun(name:string, filtersettings:table):boolean
function Sound:setEffect(name, enable)
    return self.source:setEffect(name, enable)
end

--- Sets a low-pass, high-pass, or band-pass filter to apply when playing the Sound.
---@param settings table? # The filter settings to use for this Sound, with the following fields:
---@return boolean
function Sound:setFilter(settings)
    return self.source:setFilter(settings)
end

--- Sets whether the Sound should loop.
---@param loop boolean # True if the source should loop, false otherwise.
function Sound:setLooping(loop)
    self.source:setLooping(loop)
end

--- Sets the pitch of the Sound.
---@param pitch number # Calculated with regard to 1 being the base pitch. Each reduction by 50 percent equals a pitch shift of -12 semitones (one octave reduction). Each doubling equals a pitch shift of 12 semitones (one octave increase). Zero is not a legal value.
function Sound:setPitch(pitch)
    self.source:setPitch(pitch)
end

--- Sets the position of the Sound. Please note that this only works for mono (i.e. non-stereo) sound files!
---@param x number # The X position of the Sound.
---@param y number # The Y position of the Sound.
---@param z number # The Z position of the Sound.
function Sound:setPosition(x, y, z)
    self.source:setPosition(x, y, z)
end

--- Sets whether the Sound's position, velocity, direction, and cone angles are relative to the listener, or absolute.
--- 
--- By default, all sources are absolute and therefore relative to the origin of love's coordinate system 0, 0. Only absolute sources are affected by the position of the listener. Please note that positional audio only works for mono (i.e. non-stereo) sources. 
---@param enable boolean? # True to make the position, velocity, direction and cone angles relative to the listener, false to make them absolute. (Defaults to false.)
function Sound:setRelative(enable)
    self.source:setRelative(enable)
end

--- Sets the rolloff factor which affects the strength of the used distance attenuation.
--- 
--- Extended information and detailed formulas can be found in the chapter '3.4. Attenuation By Distance' of OpenAL 1.1 specification.
---@param rolloff number # The new rolloff factor.
function Sound:setRolloff(rolloff)
    self.source:setRolloff(rolloff)
end

--- Sets the velocity of the Sound.
--- 
--- This does '''not''' change the position of the Sound, but lets the application know how it has to calculate the doppler effect.
---@param x number # The X part of the velocity vector.
---@param y number # The Y part of the velocity vector.
---@param z number # The Z part of the velocity vector.
function Sound:setVelocity(x, y, z)
    self.source:setVelocity(x, y, z)
end

--- Sets the current volume of the Sound.
---@param volume number # The volume for a Sound, where 1.0 is normal volume. Volume cannot be raised above 1.0.
function Sound:setVolume(volume)
    self.set_volume = volume
    self.source:setVolume(volume * self.volume)
end

--- Sets the volume limits of the source. The limits have to be numbers from 0 to 1.
---@param min number # The minimum volume.
---@param max number # The maximum volume.
function Sound:setVolumeLimits(min, max)
    self.source:setVolumeLimits(min, max)
end

--- Stops a Sound.
function Sound:stop()
    self.source:stop()
end

--- Gets the currently playing position of the Sound.
---@param unit love.TimeUnit? # The type of unit for the return value. (Defaults to 'seconds'.)
---@return number
function Sound:tell(unit)
    return self.source:tell(unit)
end

return Sound
