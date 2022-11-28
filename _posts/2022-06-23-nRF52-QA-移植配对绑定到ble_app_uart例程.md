---
layout: post
title: nRF52-QA-移植配对绑定到ble_app_uart例程
date: 2022-06-23
category: nRF52-QA
tags:
- peer 
- BOND
- BLE_APP_UART
last_modified_at: 2022-04-25T12:57:42-05:00
# excerpt_separator:  <!--more-->
---

### 一、修改main.c文件
* 在函数 static void ble_evt_handler(ble_evt_t const * p_ble_evt, void * p_context) 中注释到代码
```cpp
//        case BLE_GAP_EVT_SEC_PARAMS_REQUEST:
//            // Pairing not supported
//            err_code = sd_ble_gap_sec_params_reply(m_conn_handle, BLE_GAP_SEC_STATUS_PAIRING_NOT_SUPP, NULL, NULL);
//            APP_ERROR_CHECK(err_code);
//            break;
```

* 在函数static void ble_evt_handler(ble_evt_t const * p_ble_evt, void * p_context) 中增加代码
```cpp
//Peter add start
case BLE_GAP_EVT_PASSKEY_DISPLAY:
    {
            char        passkey[BLE_GAP_PASSKEY_LEN + 1];
            memcpy(passkey, p_ble_evt->evt.gap_evt.params.passkey_display.passkey, BLE_GAP_PASSKEY_LEN);
            passkey[BLE_GAP_PASSKEY_LEN] = 0x00;
            NRF_LOG_INFO("=== PASSKEY: %s =====",   nrf_log_push(passkey));                
            NRF_LOG_INFO("Press Button 3 to confirm, Button 4 to reject");
    }              
    break;
//Peter add end
```

* 在函数 void bsp_event_handler(bsp_event_t event) 中增加代码
```cpp
//Peter add start
extern void num_comp_reply(bool accept);
case BSP_EVENT_KEY_3:
    {
        num_comp_reply(1);  //接受配对绑定
    }
    break;
//Peter add end
```
* 在main.c中 注释代码
```cpp
///**@brief Function for starting advertising.
// */
//static void advertising_start(void)
//{
//    uint32_t err_code = ble_advertising_start(&m_advertising, BLE_ADV_MODE_FAST);
//    APP_ERROR_CHECK(err_code);
//}
```

* 在函数 int main(void) 中增加代码

![16](/assets/images/post/nRF52-QA-cfg-16.png)

```cpp
    peer_manager_init();  //Peter add
```

* 在函数 int main(void) 中修改代码
```cpp
    advertising_start(erase_bonds);  //Peter change
```

* 在函数int main(void)上方插入以下代码

```cpp

//Peter add pair and bond start
#include "peer_manager.h"
#include "peer_manager_handler.h"

#define SEC_PARAM_BOND                  1                                           /**< Perform bonding. */
#define SEC_PARAM_MITM                  1                                           /**< Man In The Middle protection not required. */
#define SEC_PARAM_LESC                  0                                           /**< LE Secure Connections not enabled. */
#define SEC_PARAM_KEYPRESS              0                                           /**< Keypress notifications not enabled. */
#define SEC_PARAM_IO_CAPABILITIES       BLE_GAP_IO_CAPS_DISPLAY_YESNO  //BLE_GAP_IO_CAPS_NONE                        /**< No I/O capabilities. */
#define SEC_PARAM_OOB                   0                                           /**< Out Of Band data not available. */
#define SEC_PARAM_MIN_KEY_SIZE          7                                           /**< Minimum encryption key size. */
#define SEC_PARAM_MAX_KEY_SIZE          16                                          /**< Maximum encryption key size. */
static pm_peer_id_t      m_peer_id;  

/**@brief Function for setting filtered whitelist.
 *
 * @param[in] skip  Filter passed to @ref pm_peer_id_list.
 */
static void whitelist_set(pm_peer_id_list_skip_t skip)
{
    pm_peer_id_t peer_ids[BLE_GAP_WHITELIST_ADDR_MAX_COUNT];
    uint32_t     peer_id_count = BLE_GAP_WHITELIST_ADDR_MAX_COUNT;

    ret_code_t err_code = pm_peer_id_list(peer_ids, &peer_id_count, PM_PEER_ID_INVALID, skip);
    APP_ERROR_CHECK(err_code);

    NRF_LOG_INFO("\tm_whitelist_peer_cnt %d, MAX_PEERS_WLIST %d",
                   peer_id_count + 1,
                   BLE_GAP_WHITELIST_ADDR_MAX_COUNT);

    err_code = pm_whitelist_set(peer_ids, peer_id_count);
    APP_ERROR_CHECK(err_code);
}

/**@brief Clear bond information from persistent storage.
 */
static void delete_bonds(void)
{
    ret_code_t err_code;

    NRF_LOG_INFO("Erase bonds!");

    err_code = pm_peers_delete();
    APP_ERROR_CHECK(err_code);
}

/**@brief Function for starting advertising.
 */
static void advertising_start(bool erase_bonds)
{
    if (erase_bonds == true)
    {
        delete_bonds();
        // Advertising is started by PM_EVT_PEERS_DELETE_SUCCEEDED event.
    }
    else
    {
        whitelist_set(PM_PEER_ID_LIST_SKIP_NO_ID_ADDR);

        ret_code_t ret = ble_advertising_start(&m_advertising, BLE_ADV_MODE_FAST);
        APP_ERROR_CHECK(ret);
    }
}

/**@brief Function for handling Peer Manager events.
 *
 * @param[in] p_evt  Peer Manager event.
 */
static void pm_evt_handler(pm_evt_t const * p_evt)
{
    pm_handler_on_pm_evt(p_evt);
    pm_handler_disconnect_on_sec_failure(p_evt);
    pm_handler_flash_clean(p_evt);

    switch (p_evt->evt_id)
    {
        case PM_EVT_CONN_SEC_SUCCEEDED:
            m_peer_id = p_evt->peer_id;
            break;

        case PM_EVT_PEERS_DELETE_SUCCEEDED:
            advertising_start(false);
            break;

        case PM_EVT_PEER_DATA_UPDATE_SUCCEEDED:
            if (     p_evt->params.peer_data_update_succeeded.flash_changed
                 && (p_evt->params.peer_data_update_succeeded.data_id == PM_PEER_DATA_ID_BONDING))
            {
                NRF_LOG_INFO("New Bond, add the peer to the whitelist if possible");
                // Note: You should check on what kind of white list policy your application should use.

                whitelist_set(PM_PEER_ID_LIST_SKIP_NO_ID_ADDR);
            }
            break;
        case PM_EVT_CONN_SEC_CONFIG_REQ:
            {
                pm_conn_sec_config_t cfg;
                cfg.allow_repairing = true;
                pm_conn_sec_config_reply(p_evt->conn_handle, &cfg);
            }
            break;
        default:
            break;
    }
}

/**@brief Function for the Peer Manager initialization.
 */
static void peer_manager_init(void)
{
    ble_gap_sec_params_t sec_param;
    ret_code_t           err_code;

    err_code = pm_init();
    APP_ERROR_CHECK(err_code);

    memset(&sec_param, 0, sizeof(ble_gap_sec_params_t));

    // Security parameters to be used for all security procedures.
    sec_param.bond           = SEC_PARAM_BOND;
    sec_param.mitm           = SEC_PARAM_MITM;
    sec_param.lesc           = SEC_PARAM_LESC;
    sec_param.keypress       = SEC_PARAM_KEYPRESS;
    sec_param.io_caps        = SEC_PARAM_IO_CAPABILITIES;
    sec_param.oob            = SEC_PARAM_OOB;
    sec_param.min_key_size   = SEC_PARAM_MIN_KEY_SIZE;
    sec_param.max_key_size   = SEC_PARAM_MAX_KEY_SIZE;
    sec_param.kdist_own.enc  = 1;
    sec_param.kdist_own.id   = 1;
    sec_param.kdist_peer.enc = 1;
    sec_param.kdist_peer.id  = 1;

    err_code = pm_sec_params_set(&sec_param);
    APP_ERROR_CHECK(err_code);

    err_code = pm_register(pm_evt_handler);
    APP_ERROR_CHECK(err_code);
}

void num_comp_reply(bool accept)
{
    uint8_t    key_type;
    ret_code_t err_code;
        NRF_LOG_INFO("m_conn_handle %d", m_conn_handle);
        if (m_conn_handle == BLE_CONN_HANDLE_INVALID) 
        {
            return;
        }
    if (accept)
    {
        NRF_LOG_INFO("Numeric Match");
        key_type = BLE_GAP_AUTH_KEY_TYPE_PASSKEY;
    }
    else
    {
        NRF_LOG_INFO("Numeric REJECT");
        key_type = BLE_GAP_AUTH_KEY_TYPE_NONE;
    }

    err_code = sd_ble_gap_auth_key_reply(m_conn_handle,
                                         key_type,
                                         NULL);
    APP_ERROR_CHECK(err_code);
}

//Peter add end

```

### 二、修改sdk_config.h配置文件
* 使能fds宏定义
```cpp
#ifndef FDS_ENABLED
#define FDS_ENABLED 1
#endif
```

* 使能FS存储宏定义
```cpp
#ifndef NRF_FSTORAGE_ENABLED
#define NRF_FSTORAGE_ENABLED 1
#endif
```

* 使能配对绑定宏定义

```cpp

// <e> PEER_MANAGER_ENABLED - peer_manager - Peer Manager
//==========================================================
#ifndef PEER_MANAGER_ENABLED
#define PEER_MANAGER_ENABLED 1
#endif
// <o> PM_MAX_REGISTRANTS - Number of event handlers that can be registered. 
#ifndef PM_MAX_REGISTRANTS
#define PM_MAX_REGISTRANTS 3
#endif

// <o> PM_FLASH_BUFFERS - Number of internal buffers for flash operations. 
// <i> Decrease this value to lower RAM usage.

#ifndef PM_FLASH_BUFFERS
#define PM_FLASH_BUFFERS 4
#endif

// <q> PM_CENTRAL_ENABLED  - Enable/disable central-specific Peer Manager functionality.
 

// <i> Enable/disable central-specific Peer Manager functionality.

#ifndef PM_CENTRAL_ENABLED
#define PM_CENTRAL_ENABLED 0
#endif

// <q> PM_SERVICE_CHANGED_ENABLED  - Enable/disable the service changed management for GATT server in Peer Manager.
 

// <i> If not using a GATT server, or using a server wihout a service changed characteristic,
// <i> disable this to save code space.

#ifndef PM_SERVICE_CHANGED_ENABLED
#define PM_SERVICE_CHANGED_ENABLED 1
#endif

// <q> PM_PEER_RANKS_ENABLED  - Enable/disable the peer rank management in Peer Manager.
 

// <i> Set this to false to save code space if not using the peer rank API.

#ifndef PM_PEER_RANKS_ENABLED
#define PM_PEER_RANKS_ENABLED 1
#endif

// <q> PM_LESC_ENABLED  - Enable/disable LESC support in Peer Manager.
 

// <i> If set to true, you need to call nrf_ble_lesc_request_handler() in the main loop to respond to LESC-related BLE events. If LESC support is not required, set this to false to save code space.

#ifndef PM_LESC_ENABLED
#define PM_LESC_ENABLED 0
#endif

// <e> PM_RA_PROTECTION_ENABLED - Enable/disable protection against repeated pairing attempts in Peer Manager.
//==========================================================
#ifndef PM_RA_PROTECTION_ENABLED
#define PM_RA_PROTECTION_ENABLED 0
#endif
// <o> PM_RA_PROTECTION_TRACKED_PEERS_NUM - Maximum number of peers whose authorization status can be tracked. 
#ifndef PM_RA_PROTECTION_TRACKED_PEERS_NUM
#define PM_RA_PROTECTION_TRACKED_PEERS_NUM 8
#endif

// <o> PM_RA_PROTECTION_MIN_WAIT_INTERVAL - Minimum waiting interval (in ms) before a new pairing attempt can be initiated. 
#ifndef PM_RA_PROTECTION_MIN_WAIT_INTERVAL
#define PM_RA_PROTECTION_MIN_WAIT_INTERVAL 4000
#endif

// <o> PM_RA_PROTECTION_MAX_WAIT_INTERVAL - Maximum waiting interval (in ms) before a new pairing attempt can be initiated. 
#ifndef PM_RA_PROTECTION_MAX_WAIT_INTERVAL
#define PM_RA_PROTECTION_MAX_WAIT_INTERVAL 64000
#endif

// <o> PM_RA_PROTECTION_REWARD_PERIOD - Reward period (in ms). 
// <i> The waiting interval is gradually decreased when no new failed pairing attempts are made during reward period.

#ifndef PM_RA_PROTECTION_REWARD_PERIOD
#define PM_RA_PROTECTION_REWARD_PERIOD 10000
#endif

// </e>

// <o> PM_HANDLER_SEC_DELAY_MS - Delay before starting security. 
// <i>  This might be necessary for interoperability reasons, especially as peripheral.

#ifndef PM_HANDLER_SEC_DELAY_MS
#define PM_HANDLER_SEC_DELAY_MS 0
#endif

// </e>
```

### 三、增加文件到工程
* 增加文件夹nRF_BOND，添加以下文件到工程
![15](/assets/images/post/nRF52-QA-cfg-15.png)

```cpp
.\..\..\..\..\..\..\components\ble\peer_manager\gatt_cache_manager.c
.\..\..\..\..\..\..\components\ble\peer_manager\gatts_cache_manager.c
.\..\..\..\..\..\..\components\ble\peer_manager\id_manager.c
.\..\..\..\..\..\..\components\ble\peer_manager\peer_data_storage.c
.\..\..\..\..\..\..\components\ble\peer_manager\peer_database.c
.\..\..\..\..\..\..\components\ble\peer_manager\peer_id.c
.\..\..\..\..\..\..\components\ble\peer_manager\peer_manager.c
.\..\..\..\..\..\..\components\ble\peer_manager\peer_manager_handler.c
.\..\..\..\..\..\..\components\ble\peer_manager\security_dispatcher.c
.\..\..\..\..\..\..\components\ble\peer_manager\security_manager.c
.\..\..\..\..\..\..\components\ble\peer_manager\auth_status_tracker.c
.\..\..\..\..\..\..\components\ble\peer_manager\pm_buffer.c
.\..\..\..\..\..\..\components\libraries\fds\fds.c
.\..\..\..\..\..\..\components\libraries\fstorage\nrf_fstorage.c
.\..\..\..\..\..\..\components\libraries\fstorage\nrf_fstorage_sd.c
```

