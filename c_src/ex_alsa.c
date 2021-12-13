#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <erl_nif.h>
#include <alsa/asoundlib.h>

static snd_pcm_format_t format = SND_PCM_FORMAT_FLOAT_LE;  /* sample format */
static unsigned int rate = 44100;           /* stream rate */
static unsigned int channels = 1;           /* count of channels */
static unsigned int buffer_time = 500000;       /* ring buffer length in us */
static unsigned int period_time = 2;       /* period time in us */
static int period_event = 0;                /* produce poll event after each period */
static int resample = 1;                /* enable alsa-lib resampling */
static int periods = 2;

static snd_pcm_sframes_t buffer_size;
static snd_pcm_sframes_t period_size;
#define alloca(x)  __builtin_alloca(x)

#define ERL_TERM_STRING(str) enif_make_string(env, str, ERL_NIF_LATIN1)
#define ERL_TERM_INT(val) enif_make_int(env, val)

#define ATOM(name) atm_##name

#define DECL_ATOM(name) \
    ERL_NIF_TERM atm_##name = 0

#define LOAD_ATOM(name) \
    atm_##name = enif_make_atom(env, #name)

#define BADARG_IF(cond) if (cond) return enif_make_badarg(env)
#define TO_STRING(i) #i

#define OK_TUPLE(val1) enif_make_tuple2(env, ATOM(ok), val1)
#define OK_TUPLE3(val1, val2) enif_make_tuple3(env, ATOM(ok), val1, val2)
#define ERROR_TUPLE(ret) enif_make_tuple2(env, ATOM(error), ret)

DECL_ATOM(ok);
DECL_ATOM(error);

#define FRAME_TYPE float
#define FRAME_SIZE sizeof(FRAME_TYPE)

typedef struct {
    snd_pcm_t * handle;
    unsigned int format_index;
    snd_pcm_access_t access;
    unsigned int period_size;
    unsigned int channels;
    FRAME_TYPE** channel_bufs;
    int fd;

} ex_alsa_t;

static ErlNifResourceType* resource_type;

FRAME_TYPE* get_frame_list_from_env(ErlNifEnv* env, ERL_NIF_TERM erl_list, unsigned int len);
FRAME_TYPE* get_frame_list_from_env(ErlNifEnv* env, ERL_NIF_TERM erl_list, unsigned int len) {
    FRAME_TYPE* frame_list;
    double frame;

    frame_list = (FRAME_TYPE*) enif_alloc(len*FRAME_SIZE);

    ERL_NIF_TERM curr_list = erl_list;
    for(unsigned int i=0; i<len; i++) {
        ERL_NIF_TERM hd, tl;
        enif_get_list_cell(env, curr_list, &hd, &tl);
        if(!(enif_get_double(env, hd, &frame))) {
            // error
            fprintf(stderr, "Cannot get DOUBLE\n");
        } else {
            frame_list[i] = (FRAME_TYPE) frame;
            curr_list = tl;
        }
    }
    return frame_list;
}


static ERL_NIF_TERM pcm_write(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    int sent;
    unsigned int num_frames, available_frames;
    FRAME_TYPE* buffer;
    ex_alsa_t * unit;

    BADARG_IF(!enif_get_resource(env, argv[0], resource_type, (void**) &unit));

    BADARG_IF(!enif_get_list_length(env, argv[1], &num_frames));

    buffer = get_frame_list_from_env(env, argv[1], num_frames);

    available_frames = snd_pcm_avail_update(unit->handle);

    if (available_frames < num_frames) {
        return ERROR_TUPLE(ERL_TERM_INT(available_frames));
    }

    sent = snd_pcm_writei(unit->handle, buffer, num_frames);
    if(sent < 0) {
        fprintf(stderr, "Error %s", strerror(sent));
        snd_pcm_recover(unit->handle, sent, 0);
    }
    available_frames = snd_pcm_avail_update(unit->handle);

    return OK_TUPLE3(ERL_TERM_INT(sent), ERL_TERM_INT(available_frames));
}

static int set_hwparams(snd_pcm_t *handle,
        snd_pcm_hw_params_t *params,
        snd_pcm_access_t access)
{
    unsigned int rrate;
    snd_pcm_uframes_t size;
    int err, dir;

    /* choose all parameters */
    err = snd_pcm_hw_params_any(handle, params);
    if (err < 0) {
        printf("Broken configuration for playback: no configurations available: %s\n", snd_strerror(err));
        return err;
    }

    
    /* Set number of periods. Periods used to be called fragments. */ 
    /*err = snd_pcm_hw_params_set_periods(handle, params, periods, 0);
    if (err < 0) {
      printf("Error setting periods: %s\n", snd_strerror(err));
      return err;
    }*/

    /* set hardware resampling */
    err = snd_pcm_hw_params_set_rate_resample(handle, params, resample);
    if (err < 0) {
        printf("Resampling setup failed for playback: %s\n", snd_strerror(err));
        return err;
    }
    /* set the interleaved read/write format */
    err = snd_pcm_hw_params_set_access(handle, params, access);
    if (err < 0) {
        printf("Access type not available for playback: %s\n", snd_strerror(err));
        return err;
    }
    /* set the sample format */
    err = snd_pcm_hw_params_set_format(handle, params, format);
    if (err < 0) {
        printf("Sample format not available for playback: %s\n", snd_strerror(err));
        return err;
    }
    /* set the count of channels */
    err = snd_pcm_hw_params_set_channels(handle, params, channels);
    if (err < 0) {
        printf("Channels count (%u) not available for playbacks: %s\n", channels, snd_strerror(err));
        return err;
    }
    /* set the stream rate */
    rrate = rate;
    err = snd_pcm_hw_params_set_rate_near(handle, params, &rrate, 0);
    if (err < 0) {
        printf("Rate %uHz not available for playback: %s\n", rate, snd_strerror(err));
        return err;
    }
    if (rrate != rate) {
        printf("Rate doesn't match (requested %uHz, get %iHz)\n", rate, err);
        return -EINVAL;
    }
    /* set the buffer time */
    err = snd_pcm_hw_params_set_buffer_time_near(handle, params, &buffer_time, &dir);
    if (err < 0) {
        printf("Unable to set buffer time %u for playback: %s\n", buffer_time, snd_strerror(err));
        return err;
    }
    err = snd_pcm_hw_params_get_buffer_size(params, &size);
    if (err < 0) {
        printf("Unable to get buffer size for playback: %s\n", snd_strerror(err));
        return err;
    }
    buffer_size = size;
    /* set the period time */
    err = snd_pcm_hw_params_set_period_time_near(handle, params, &period_time, &dir);
    if (err < 0) {
        printf("Unable to set period time %u for playback: %s\n", period_time, snd_strerror(err));
        return err;
    }
    err = snd_pcm_hw_params_get_period_size(params, &size, &dir);
    if (err < 0) {
        printf("Unable to get period size for playback: %s\n", snd_strerror(err));
        return err;
    }
    period_size = size;
    /* write the parameters to device */
    err = snd_pcm_hw_params(handle, params);
    if (err < 0) {
        printf("Unable to set hw params for playback: %s\n", snd_strerror(err));
        return err;
    }
    return 0;
}

static int set_swparams(snd_pcm_t *handle, snd_pcm_sw_params_t *swparams)
{
    int err;

    /* get the current swparams */
    err = snd_pcm_sw_params_current(handle, swparams);
    if (err < 0) {
        printf("Unable to determine current swparams for playback: %s\n", snd_strerror(err));
        return err;
    }
    /* start the transfer when the buffer is almost full: */
    /* (buffer_size / avail_min) * avail_min */
    err = snd_pcm_sw_params_set_start_threshold(handle, swparams, period_size * 4);
    if (err < 0) {
        printf("Unable to set start threshold mode for playback: %s\n", snd_strerror(err));
        return err;
    }
    /* allow the transfer when at least period_size samples can be processed */
    /* or disable this mechanism when period event is enabled (aka interrupt like style processing) */
    err = snd_pcm_sw_params_set_avail_min(handle, swparams, period_event ? buffer_size : period_size);
    if (err < 0) {
        printf("Unable to set avail min for playback: %s\n", snd_strerror(err));
        return err;
    }
    /* enable period events when requested */
    if (period_event) {
        err = snd_pcm_sw_params_set_period_event(handle, swparams, 1);
        if (err < 0) {
            printf("Unable to set period event: %s\n", snd_strerror(err));
            return err;
        }
    }
    /* write the parameters to the playback device */
    err = snd_pcm_sw_params(handle, swparams);
    if (err < 0) {
        printf("Unable to set sw params for playback: %s\n", snd_strerror(err));
        return err;
    }
    return 0;
}


static ERL_NIF_TERM pcm_open_handle(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    char device[128];
    int err = 0;
    ex_alsa_t * unit = enif_alloc_resource(resource_type, sizeof(ex_alsa_t));
    snd_pcm_t** handle_p = &unit->handle;

    BADARG_IF(!enif_get_string(env, argv[0], device, 128, ERL_NIF_LATIN1));


    //if ((err = snd_pcm_open(handle_p, device, SND_PCM_STREAM_PLAYBACK, SND_PCM_NONBLOCK)) < 0) {
    if ((err = snd_pcm_open(handle_p, device, SND_PCM_STREAM_PLAYBACK, 0)) < 0) {
        printf("Playback open error: %s\n", snd_strerror(err));
        return enif_make_badarg(env);
    }

    ERL_NIF_TERM term = enif_make_resource(env, unit);
    enif_release_resource(unit);
    return OK_TUPLE(term);
}

static ERL_NIF_TERM pcm_set_params(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    unsigned int channels, rate, buffer_period_size_ratio, stop_threshold;
    int ret;
    snd_pcm_uframes_t buffer_size, period_size; // ulong

    snd_pcm_hw_params_t *hwparams;
    snd_pcm_hw_params_alloca(&hwparams);

    snd_pcm_sw_params_t *swparams;
    snd_pcm_sw_params_alloca(&swparams);
    ex_alsa_t * unit;
    BADARG_IF(!enif_get_resource(env, argv[0], resource_type, (void**) &unit));
    BADARG_IF(!enif_get_uint(env, argv[1], &channels));
    BADARG_IF(!enif_get_uint(env, argv[2], &rate));
    BADARG_IF(!enif_get_ulong(env, argv[3], &period_size));
    BADARG_IF(!enif_get_uint(env, argv[4], &buffer_period_size_ratio));
    BADARG_IF(!enif_get_uint(env, argv[5], &stop_threshold));

    ret = set_hwparams(unit->handle, 
            hwparams,
            SND_PCM_ACCESS_RW_INTERLEAVED
            );
    if (ret < 0) {
        return ERROR_TUPLE(enif_make_uint(env, ret));
    }

    ret = set_swparams(unit->handle, 
            swparams
            );
    if (ret < 0) {
        return ERROR_TUPLE(enif_make_uint(env, ret));
    }


    snd_output_t* out;
    snd_output_stdio_attach(&out, stderr, 0);
    snd_pcm_dump_sw_setup(unit->handle, out);
    snd_pcm_dump_hw_setup(unit->handle, out);

    // TODO turn this into a map
    // https://dnlserrano.dev/2019/03/10/elixir-nifs.html
    return OK_TUPLE(
            enif_make_tuple5(env,
                enif_make_uint(env, rate),
                enif_make_uint(env, channels),
                enif_make_ulong(env, buffer_size),
                enif_make_ulong(env, period_size),
                enif_make_uint(env, stop_threshold)
                ));
}

static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info)
{
    LOAD_ATOM(ok);
    LOAD_ATOM(error);

    int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
    resource_type = enif_open_resource_type(env, "ex_alsa_nif", "handle", NULL, flags, NULL);
    if (resource_type == NULL) return -1;
    return 0;
}

static ErlNifFunc funcs[] = {
    { "write", 2, pcm_write, ERL_NIF_DIRTY_JOB_CPU_BOUND},
    { "_set_params", 6, pcm_set_params},
    { "_open_handle", 1, pcm_open_handle},
};

ERL_NIF_INIT(Elixir.ExAlsa, funcs, load, NULL, NULL, NULL)
