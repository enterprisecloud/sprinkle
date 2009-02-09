module Sprinkle
  # Usage:
  #
  #   Sprinke::Verify.new("some description")  do
  #     has_gem("sprinkle")
  #     has_executables("ruby")
  #     has_process("mysqld_safe")
  #     has_file("/etc/my.cnf")
  #     has_directory("/etc")
  #   end
  #
  # == Available Verifiers
  #
  # There are a variety of available methods for use in the verification block.
  # The standard methods are defined in the Sprinkle::Verifiers module, so see
  # their corresponding documentation.
  #
  # == Custom Verifiers
  # 
  # If you feel that the built-in verifiers do not offer a certain aspect of
  # verification which you need, you may create your own verifier! Simply wrap
  # any method in a module which you want to use:
  #
  #   module MagicBeansVerifier
  #     def has_magic_beans(sauce)
  #       @commands << '[ -z "`echo $' + sauce + '`"]'
  #     end
  #   end
  #
  # The method can append as many commands as it wishes to the @commands array. 
  # These commands will be run on the remote server and <b>MUST</b> give an
  # exit status of 0 if successful or other if unsuccessful.
  #
  # To register your verifier, call the register method on Sprinkle::Verify:
  #
  #   Sprinle::Verify.register(MagicBeansVerifier)
  #
  # And now you may use it like any other verifier:
  #
  #   package :magic_beans do
  #     gem 'magic_beans'
  #     
  #     verify { has_magic_beans('ranch') }
  #   end
  class Verify
    attr_accessor :description, :commands #:nodoc:
    
    class <<self
      # Register a verification module
      def register(new_module)
        class_eval { include new_module }
      end
    end
    
    def initialize(description = '', &block) #:nodoc:
      raise 'Verify requires a block.' unless block
      
      @description = description
      @commands = []
      @options ||= {}
      @options[:padding] = 4
      
      self.instance_eval(&block)
    end
    
    def process(roles, pre = false) #:nodoc:
      description = @description
      
      if logger.debug?
        logger.debug "#{description} verification sequence: #{@commands.join('; ')} for roles: #{roles}\n"
      end
      
      unless Sprinkle::OPTIONS[:testing]
        logger.info "#{" " * @options[:padding]}--> Verifying #{description}..."
        
        unless @delivery.process(@commands, roles, true)
          # Verification failed, halt sprinkling gracefully.
          raise Sprinkle::VerificationFailed.new(description)
        end
      end
    end
  end
  
  class VerificationFailed < Exception #:nodoc:
    attr_accessor :description
    
    def initialize(description)
      super("Verifying #{description} failed.")
      
      @description = description
    end
  end
end