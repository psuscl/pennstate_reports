class LinkedTopContainerSubreport < AbstractSubreport

    register_subreport('top_container', ['archival_object'])

    def initialize(parent_report, archival_object_id)
        super(parent_report)
        @archival_object_id = archival_object_id
    end

    def query_string
        "select
            top_container.type_id as top_container_type,
            top_container.indicator as indicator
        from archival_object
            
            left outer join instance
                on instance.archival_object_id = archival_object.id
            
            left outer join sub_container
                on sub_container.instance_id = instance.id
            
            left outer join top_container_link_rlshp
                on top_container_link_rlshp.sub_container_id = sub_container.id
            
            left outer join top_container
                on top_container.id = top_container_link_rlshp.top_container_id
            
        where archival_object.id = #{db.literal(@archival_object_id)}
            and top_container.type_id is not null"

    end

    def fix_row(row)
        ReportUtils.get_enum_values(row, [:top_container_type])
        row[:name] = "#{row[:top_container_type]} #{row[:indicator]}"
        row.delete(:top_container_type)
        row.delete(:indicator)
    end

    def self.field_name
      'name'
    end
end
