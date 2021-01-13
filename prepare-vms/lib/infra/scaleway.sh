if ! command -v scw >/dev/null; then
  warn "Scaleway CLI (scw) not found."
fi
if ! [ -f ~/.config/scw/config.yaml ]; then
  warn "~/.config/scw/config.yaml not found."
fi

infra_list() {
    scw instance server list -o json |
        jq -r '.[] | [.id, .name, .state, .commercial_type] | @tsv'
}

infra_start() {
    COUNT=$1

    SCW_INSTANCE_TYPE=${SCW_INSTANCE_TYPE-DEV1-M}
    SCW_ZONE=${SCW_ZONE-fr-par-1}

    for I in $(seq 1 $COUNT); do
        NAME=$(printf "%s-%03d" $TAG $I)
        sep "Starting instance $I/$COUNT"
        info "          Zone: $SCW_ZONE"
        info "          Name: $NAME"
        info " Instance type: $SCW_INSTANCE_TYPE"
        scw instance server create \
            type=${SCW_INSTANCE_TYPE} zone=${SCW_ZONE} \
            image=ubuntu_bionic name=${NAME}
    done
    sep

    scw_get_ips_by_tag $TAG > tags/$TAG/ips.txt
}

infra_stop() {
    info "Counting instances..."
    scw_get_ids_by_tag $TAG | wc -l
    info "Deleting instances..."
    scw_get_ids_by_tag $TAG | 
        xargs -n1 -P10 -I@@ \
        scw instance server delete force-shutdown=true server-id=@@
}

scw_get_ids_by_tag() {
    TAG=$1
    scw instance server list name=$TAG -o json | jq -r .[].id
}

scw_get_ips_by_tag() {
    TAG=$1
    scw instance server list name=$TAG -o json | jq -r .[].public_ip.address
}
