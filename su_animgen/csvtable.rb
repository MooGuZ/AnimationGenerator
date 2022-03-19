# This file provide a class CSVTable to read and write CSV files
#
# MooGu Z. <hzhu@case.edu>
# Apr 11, 2015

# load system lib
require "csv"
require "forwardable"

# define array converter
CSV::Converters[:array] = lambda do |field|
  return field && field.match(/^\[[0-9,]*\]$/) ? 
         field.gsub(/[\[\]]/,'').split(',').map {|s| s.to_f} : 
         field
end

# class start: CSVTable
class CSVTable 
  extend Forwardable
  
  # attributions
  attr :table
  
  # defeine forward functions
  def_delegators :@table, :size, :<<, :==, :[], :[]=, :headers,
                          :each, :map, :to_a, :to_csv, :to_s
  
  # constructor: 
  # - create an empty CSVTable with header
  # - create an CSVTable from CSV::Table
  def initialize(var)
    @table = var.is_a?(CSV::Table) ?
             var :
             CSV::Table.new([CSV::Row.new(var,var.map{|h| h.to_s},true)])
  end
  
  # load csv file with header
  def self.read(fname)
    # check existence of csv file
    return nil unless File.exist?(fname)
    # read csv file with header
    table = CSV.read(fname, 
              :headers => true, 
              :header_converters => :downcase, 
              :converters => [:all,:array],
              :return_headers => false)
    return CSVTable.new(table)
  end
  
  # find or create a row
  def row
    # find a row if block given
    @table.each {|r| return r if yield(r)} if block_given?
    # else create a new row in the end
    r = CSV::Row.new(@table.headers,[],false)
    @table << r
    return r
  end
  
  # write table into file
  def write(fname)
    CSV::open(fname,"wb",
      :write_headers => true,
      :headers => @table.headers) do |file|
        @table.each {|row| file << row unless row.header_row?}
    end
  end
end
# class end: CSVTable