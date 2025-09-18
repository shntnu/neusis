# Hardware Reference

## Server Specifications

Detailed hardware inventory maintained in imaging-server-maintenance:

- [Local](../../../../misc/imaging-server-maintenance/INVENTORY.md) | [GitHub](https://github.com/broadinstitute/imaging-server-maintenance/blob/main/INVENTORY.md)

## Quick Reference

### Oppy

- **IPs**: 10.192.6.25 (primary), 10.192.5.25 (BMC), 192.0.2.1 (InfiniBand)
- **GPUs**: 4x NVIDIA H100 NVL (94GB each)
- **Storage**: 8 drives (ZFS pools zstore16, zstore03)

### Network Ports

- **Front Panel**: BMC RJ45, Management port, VGA, USB
- **Rear Panel**: 2x Intel X710 (fiber), Mellanox QSFP (InfiniBand)

## Physical Access

Location: Markley Group, 1 Summer Street, Boston

- Rack: C17, U17-20 (Oppy top, Spirit bottom)
- Access: ServiceNow ticket via <help@broadinstitute.org>

Photos and diagrams: [Local](../../../../misc/imaging-server-maintenance/hardware/) | [GitHub](https://github.com/broadinstitute/imaging-server-maintenance/tree/main/hardware/)
