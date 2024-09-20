require "simplecov"
require "simplecov-console"
require "simplecov-cobertura"
SimpleCov.formatter SimpleCov::Formatter::MultiFormatter
  .new([
         SimpleCov::Formatter::Console,
         SimpleCov::Formatter::CoberturaFormatter
       ])
SimpleCov.start
