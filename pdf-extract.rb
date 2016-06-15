require 'pdf/reader'

class PDFInfo
    attr_reader :objects
    
    def initialize input, pwd=""  
        @input = input
        
        @pdf = PDF::Reader.new input if pwd.empty?
        @pdf = PDF::Reader.new(input, :password=>pwd) unless pwd.empty?
        
        @objects = @pdf.objects
        page = getPageObject 1
        
        @root = page.cache.values[0]
        @structRoot = @objects[@root[:StructTreeRoot]]
        
    end
    
    def getPageCount
        @pdf.page_count
    end

    def getPageObject pagenum
        @pdf.page pagenum
    end
    
    # return array or empty from pdf given
    def getTags
        str = ""    
        @tag_confirm = false
        if is_tagging?
            tags = @objects[@structRoot[:RoleMap]]
            tags.each do |k, v|
                str << '/' + k.to_s + '         ' + '/' + v.to_s + "\n"
            end
        end
        puts "No taggable list" if str.empty?
#        File.open('tags_list_from_' + @input + '.txt', 'w+') {|f|  f.write(str)} unless str.empty?        
        puts "Taggable List"
        puts str
    end
    
    def is_tagging? 
        tag_confirm = false
        tag_confirm = true if @structRoot
        
        tag_confirm
    end
    
    def getLangDef
        str = ""        
        str = @root[:Lang] if @root[:Lang]
        puts "Language Define " + str unless str.empty?
        puts "Language Not Defined" if str.empty?
    end
    
    def getHeadings
        return unless is_tagging?
        str = ""
        heading = %i(H1 H2 H3 H4 H5 H6)
        
        @objects.each do |_o|
            o = @objects[_o]
            _str = ""
            
            if o.is_a?(Hash)               
                if o[:S] && (heading.include?o[:S])                   
                    o[:K].each do |_head|
                        next unless _head.is_a?(PDF::Reader::Reference)
                        _str << @objects[_head][:ActualText] if @objects[_head].has_key?(:ActualText) && @objects[_head]
                        puts _str
                    end
                    str << "Heading Style: " + o[:S].to_s + "   " + "Text: " + _str + "\n" unless _str.empty?
                end
            end
        end
        puts str
        puts "Heading Style not used" if str.empty?
#        File.open("heading_list_from_"+@input+".txt", "w+") { |f| f.write(str)} unless str.empty?
        puts "Heading Style List"
        puts str
    end
    
    
    
    def getBookMarks
        if !@root.has_key?(:Outlines)
            puts "BookMark list not defined!"
            return
        end
        
        outlines = @objects[@root[:Outlines]]        
        count = outlines[:Count]
        outlines = @objects[outlines[:First]]
        array = _get_book_mark outlines, " "
        
        puts "BookMarks Array List:"
        puts array
    end
    
    
    def is_Heading1?
        heading = %i(H1 H2 H3 H4 H5 H6)
        head = ''
        @objects.each do |_o|
            o = @objects[_o]
            if o.is_a?(Hash)               
                if o[:S] && (heading.include?o[:S])                   
                    head = o[:S]
                    break
                end
            end
        end
        if head == :H1
            puts "True"
            return true 
        else
            puts "False"
            return false
        end
    end
    
    def getImageWithOutAlt
        page_list = []
        @objects.each do |_o|
            o = get_object_by_ref(_o)
            if o.is_a?(Hash)
                if o[:S] == :Figure && !o.key?(:Alt) 
                    h = get_object_by_ref(o[:Pg])             
                    number = _get_pdf_page_number_by_page_object(h)                    
                    page_list << number if number
                end
            end
        end
        
        puts "Alternative Image Not." if page_list == []
#        File.open("Alt_Image_Page_list" +@input+ ".txt", "w+"){|f| f.write(page_list)} unless page_list == []
        puts "Alternative Image List" unless page_list == []
        puts page_list
    end
    
    def getTableWithOutHeading
        page_list = []
        @objects.each do |_o|
            o = get_object_by_ref(_o)
            if o.is_a?(Hash)
                if o[:S] == :Table
                    number = has_table_without_heading o
                    page_list << number if number != 0
                end
            end
        end
        
        puts "Table without heading not found" if page_list == []
        puts "Table without page list" unless page_list == []
        puts page_list
    end
    
    def getTitle
        str = ""
        puts @pdf.info
        str = @pdf.info[:Title] if @pdf.info.has_key?(:Title)
        puts "Title not defined" if str == ""
        puts "Title: " + str unless str==""
    end
    
    
    private
    
    def _get_pdf_page_number_by_page_object object
        @pdf.pages.each do |p|
            return p.number if object == p.page_object
        end
    end
    
    def _get_book_mark object, str    
        array = []  
        s = "."
        while 1 do
            break unless object
            if object.has_key?(:First)  
                s = "." * (str.length / 2)
                array << s + object[:Title]
                array << _get_book_mark(get_object_by_ref(object[:First]), s + object[:Title])
                object = get_object_by_ref(object[:Next])    
            elsif object.has_key?(:Next) && !object.has_key?(:First)
                s = "." * (str.length / 2)
                array << s + ": " + object[:Title]
                object = get_object_by_ref(object[:Next])                
            elsif !object.has_key?(:Next) && !object.has_key?(:First)
                s = "." * (str.length / 2)
                array << str + ": " + object[:Title]
                break
            end               
        end 
        array
    end
    
    def get_object_by_ref(ref)
        o = @objects[ref]
        o
    end
    
    def has_table_without_heading object
        number = 0
        kids_body = []
        return number unless object.has_key?(:Pg)
        kids = get_object_by_ref(object[:K])        
        if kids[:S] == :TBody            
            kids_body = get_object_by_ref(kids[:K]) unless kids[:K].is_a?(Array)
            kids_body = get_object_by_ref(kids[:K][0]) if kids[:K].is_a?(Array)
        end       
        kids = kids_body if kids_body
        data_cell = get_object_by_ref(kids[:K][0]) if kids[:K].is_a?(Array)
        data_cell = get_object_by_ref(kids[:K]) unless kids[:K].is_a?(Array)
        return number if data_cell[:S] != :TH
        
        number = _get_pdf_page_number_by_page_object(get_object_by_ref(object[:Pg]))
        number
    end   
end
